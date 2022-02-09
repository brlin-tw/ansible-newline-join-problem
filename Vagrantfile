# -*- mode: ruby -*-
# vi: set ft=ruby :
# Vagrant configuration file
# Reference:
#   - Vagrantfile - Vagrant by HashiCorp
#     https://www.vagrantup.com/docs/vagrantfile/
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://app.vagrantup.com/boxes/search.
  # The bento boxes supports synced folders
  config.vm.box = "bento/centos-7"
  #config.vm.box = "centos/7"

  disk1_image_file = "#{Dir.pwd}/disk1.vdi"
  disk2_image_file = "#{Dir.pwd}/disk2.vdi"
  disk3_image_file = "#{Dir.pwd}/disk3.vdi"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  # https://www.vagrantup.com/docs/virtualbox/configuration.html
  config.vm.provider "virtualbox" do |v|
    # Customize the amount of memory on the VM
    # Use too much may causes host system thrashing
    # Acer: 8GiB
    # Dell: 16GiB
    v.memory = "512"

    # Optimize for 4 CPU cores (possibly with 8 CPU threads) notebooks
    # The sane value is how many physical cores your system has
    v.cpus = 4

    # Use VirtIO NIC for better performance
    # https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm-networking
    v.default_nic_type = "virtio"

    # 建立用來實驗的多磁碟機/硬盤環境
    # https://www.vagrantup.com/docs/virtualbox/configuration.html#vboxmanage-customizations
    v.customize [
      "storagectl", :id,
      "--name", "SATA Controller",
      "--portcount", "6",
      "--hostiocache", "on"
    ]
    unless File.exist? (disk1_image_file)
      v.customize [
        "createmedium", "disk",
        "--filename", "#{disk1_image_file}",
        "--size", "1024"
      ]
      v.customize [
        "storageattach", :id,
        "--storagectl", "SATA Controller",
        "--type", "hdd",
        "--port", "1",
        "--medium", "#{disk1_image_file}"
      ]
    end
    unless File.exist? (disk2_image_file)
      v.customize [
        "createmedium", "disk",
        "--filename", "#{disk2_image_file}",
        "--size", "1024"
      ]
      v.customize [
        "storageattach", :id,
        "--storagectl", "SATA Controller",
        "--type", "hdd",
        "--port", "2",
        "--medium", "#{disk2_image_file}"
      ]
    end
    unless File.exist? (disk3_image_file)
      v.customize [
        "createmedium", "disk",
        "--filename", "#{disk3_image_file}",
        "--size", "1024"
      ]
      v.customize [
        "storageattach", :id,
        "--storagectl", "SATA Controller",
        "--type", "hdd",
        "--port", "3",
        "--medium", "#{disk3_image_file}"
      ]
    end
  end

  # Shared-folder configuration
  # the vagrant file residing folder is mapped/copied into /vagrant
  config.vm.synced_folder ".",
    "/vagrant",
    owner: "vagrant",
    group: "vagrant",
    mount_options: [
      # Avoid some program errored due to excessive access from `other`
      "fmode=0770",
      "dmode=0770"
    ]
  config.vm.provision "shell", inline: <<-EOF
    printf 'cd /vagrant\n' >> ~vagrant/.bash_profile
  EOF

  config.vm.define "default" do |default|
    # Customize in-Virtualbox VM name
    # default.vm.provider "virtualbox" do |v|
    #   v.name = "_project_name_.default"
    # end

    # Customize in-VM hostname
    default.vm.hostname = "default"

    # Port forwarding configuration
    default.vm.network "forwarded_port", guest: 22, host: 2222, host_ip: "127.0.0.1", id: "ssh", auto_correct: true

    # Remove virtual disk when destroying VM
    default.trigger.after :destroy do |trigger|
      File.delete(disk1_image_file) if File.exist?(disk1_image_file)
      File.delete(disk2_image_file) if File.exist?(disk2_image_file)
      File.delete(disk3_image_file) if File.exist?(disk3_image_file)
    end

    #default.vm.provision "shell", inline: <<-EOF
      #yum install --assumeyes rsync
    #EOF
    #default.vm.provision "shell", path: "provision-default.bash"

    #default.vm.provision :ansible do |ansible|
      #ansible.playbook = "playbooks/deploy.yml"
      #ansible.inventory_path = "inventory/development_local"
    #end
  end
end
