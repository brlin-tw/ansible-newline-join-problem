# Ansible problem where merging newline-including string list using join filter creates string with literal newline escape sequence

A confusing problem that is quadrupled by YAML, Ansible, Python, and Jinja.

## Prerequisites

* Ansible

## Reproduction

1. Clone this repository
1. Launch a text terminal
1. Change working directory to the local repository
1. Run `ansible-playbook playbooks/reproduce.yml` command to run the bug reproduction playbook
1. Check the rendered template(rendered-template*.txt) in the working directory

## Expected result

* All newline escape sequences(`\n`) in all of the elements of the `input` sequence are rendered as newline
* All elements of the `input` sequence are separated by 1 newline

```
line
with
newlines
line
with
newlines
line
with
newlines
```

## Problematic result

* All elements of the `input` sequence are separated by literal escape sequence of newline(`\n`) but not the actual newline

```
line
with
newlines\nline
with
newlines\nline
with
newlines
```

## Reference

* [Ansible Template Tester](https://ansible.sivel.net/test/)  
  Useful utility to test how a Jinja2 template renders(with Ansible-specific filters)
* [Jinja live parser](https://cryptic-cliffs-32040.herokuapp.com/)  
  Useful utility to test how a Jinja2 template renders(without Ansible-specific filters)
