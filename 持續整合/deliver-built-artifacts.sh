#!/usr/bin/env bash
# Package and deliver built artifacts
# NOTE: GITLAB_AUTH_TOKEN is supplied externally
set -eu

apk add \
    curl \
    git \
    git-lfs \
    jq \
    python3 \
    py3-pip \
    tar \
    yq

pip install \
    git-archive-all

GIT_SSL_NO_VERIFY='' git lfs pull

project_slug="${DRONE_REPO}"
project_slug_components="$(echo "${project_slug}" | tr / ' ')"
project_slug_escaped="$(
    printf "%s" "${project_slug}" \
        | sed 's@/@%2F@'
)"
project_id="${project_slug##*/}"

echo DEBUG: DRONE_BUILD_EVENT: "${DRONE_BUILD_EVENT}"

git_tag_list="$(
    git tag \
        --list
)"
git_tag_count="$(
    git tag \
        --list \
        | wc -l
)"
git_describe="$(
    git describe \
        --always \
        --dirty \
        --tags
)"
echo DEBUG: git_describe: "${git_describe}"

if test "${git_tag_count}" -eq 0; then
    deploy_mode=snapshot
else
    git_latest_tag="$(
        printf "%s\n" "${git_tag_list}" \
            | sort -rV \
            | head -n1
    )"
    echo DEBUG: git_latest_tag: "${git_latest_tag}"
    if test "${git_describe}" != "${git_latest_tag}"; then
        deploy_mode=snapshot
    else
        deploy_mode=release
    fi
fi

echo DEBUG: deploy_mode: "${deploy_mode}"

# 只讓 tag 事件創建釋出版本
if test "${deploy_mode}" == release \
    && test "${DRONE_BUILD_EVENT}" != tag; then
    printf 'Skip creating release in non-tag event.\n'
    exit 0
fi

case "${git_tag_count}" in
    0\
    |1)
        git_changelog="$(
            git log \
                --format='format:- %h - %s （%aN）' \
                --no-decorate \
                --abbrev-commit
        )"
    ;;
    *)
        git_previous_tag="$(
            printf '%s\n' "${git_tag_list}" \
                | sort -rV \
                | sed -n 2p
        )"
        echo DEBUG: git_previous_tag: "${git_previous_tag}"
        git_changelog="$(
            git log \
                --format='format:- %h - %s （%aN）' \
                --no-decorate \
                --abbrev-commit \
                "${git_previous_tag}..${git_latest_tag}"
        )"
    ;;
esac

if test "${deploy_mode}" = release; then
    echo Remove release if release is already created...
    # NOTE: 如果找不到釋出版本會返回 403 而非 404
    if test "$(
        curl \
            --head \
            --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" \
            --insecure \
            --location \
            --output /dev/null \
            --request GET \
            --silent \
            --write-out '%{http_code}' \
            "https://gitlab.itzxa.local/api/v4/projects/${project_slug_escaped}/releases/${git_latest_tag}"
        )" == 200; then
        curl \
            --fail \
            --head \
            --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" \
            --insecure \
            --show-error \
            --silent \
            --request DELETE \
            "https://gitlab.itzxa.local/api/v4/projects/${project_slug_escaped}/releases/${git_latest_tag}"
            # 補上 GitLab 輸出缺少的換行
            printf '\n\n'
    fi

    echo Fetching project display name...
    project_display_name="$(
        curl \
            --fail \
            --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" \
            --insecure \
            --show-error \
            --silent \
            "https://gitlab.itzxa.local/api/v4/projects/${project_slug_escaped}" \
            | jq \
                --raw-output \
                .name
    )"

    echo Creating GitLab release...
    curl \
        --fail \
        --show-error \
        --silent \
        --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" \
        --form "name=${project_display_name:-"${project_id}"} 第 ${git_latest_tag#v} 版" \
        --form "tag_name=${git_latest_tag}" \
        --form "description=## 變更一覽 ##
${git_changelog}" \
        --request POST \
        --insecure \
        "https://gitlab.itzxa.local/api/v4/projects/${project_slug_escaped}/releases"
        # 補上 GitLab 輸出缺少的換行
        printf '\n\n'
fi

release_id="${project_id}-${git_describe#v}"
built_artifact_uncompressed="${release_id}.tar"
git-archive-all \
    --prefix="${release_id}/" \
    "${built_artifact_uncompressed}"

echo Injecting Ansible requirements to the archive...
for role_name in $(yq e '.roles[].name' requirements.yml); do
    tar \
        --append \
        --file "${built_artifact_uncompressed}" \
        --transform "s@^@${release_id}/@" \
        --verbose \
        "playbooks/roles/${role_name}"
done

for collection_id in $(yq e '.collections[].name' requirements.yml); do
    #collection_namespace="${collection_id%%.*}"
    #collection_name="${collection_id##*.}"
    tar \
        --append \
        --file "${built_artifact_uncompressed}" \
        --transform "s@^@${release_id}/@" \
        --verbose \
        "playbooks/collections/ansible_collections/${collection_id//.//}"
done

echo Compressing project artifact archive...
gzip \
    --verbose \
    "${built_artifact_uncompressed}"
built_artifact="${built_artifact_uncompressed}.gz"

echo Creating project artifact folder...
subpath=
for project_slug_component in ${project_slug_components}; do
    subpath="${subpath}/${project_slug_component}"
    if test "$(
            curl \
                --fail \
                --location \
                --output /dev/null \
                --silent \
                --write-out "%{http_code}" \
                "http://files.itzxa.local/持續交付/${subpath}"
        )" == 404; then
        if ! \
            curl \
                --fail \
                --location \
                --request MKCOL \
                --show-error \
                --silent \
                "http://files.itzxa.local/持續交付/${subpath}" \
                > /dev/null; then
            printf -- \
                'Error: Unable to create folder "%s"' \
                "/持續交付/${subpath}" \
                1>&2
            exit 1
        fi
    fi
done

for built_artifact in \
    "${release_id}"*.tar*; do

    built_artifact_filename="${built_artifact##*/}"

    case "${deploy_mode}" in
        release)
            asset_url="http://files.itzxa.local/持續交付/${project_slug}/${built_artifact_filename}"

            echo Uploading release artifact "${built_artifact_filename}"...
            curl \
                --fail \
                --show-error \
                --silent \
                --upload-file "${built_artifact}" \
                "${asset_url}"

            echo Creating GitLab release link...
            curl \
                --fail \
                --show-error \
                --silent \
                --header "Authorization: Bearer ${GITLAB_AUTH_TOKEN}" \
                --form "name=${built_artifact}" \
                --form "url=${asset_url}" \
                --request POST \
                --insecure \
                "https://gitlab.itzxa.local/api/v4/projects/${project_slug_escaped}/releases/${git_latest_tag}/assets/links"
        ;;
        snapshot)
            asset_url="http://files.itzxa.local/持續交付/${project_slug}/開發中版本/${built_artifact_filename}"

            echo Ensure development snapshot folder is created...
            if test "$(
                    curl \
                        --fail \
                        --location \
                        --output /dev/null \
                        --silent \
                        --write-out "%{http_code}" \
                        "${asset_url%/*}"
                )" == 404; then
                if ! \
                    curl \
                        --fail \
                        --location \
                        --request MKCOL \
                        --show-error \
                        --silent \
                        "${asset_url%/*}"; then
                    printf -- \
                        'Error: Unable to create the development snapshot folder' \
                        1>&2
                    exit 1
                fi
            fi

            echo Uploading development snapshot "${built_artifact_filename}"...
            curl \
                --fail \
                --show-error \
                --silent \
                --upload-file "${built_artifact}" \
                "${asset_url}"
        ;;
        *)
            printf \
                'FATAL: Invalid deploy_mode "%s" specified.\n' \
                "${deploy_mode}" \
                1>&2
            exit 1
        ;;
    esac
done
