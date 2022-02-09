# 設備清單<br>inventory

此目錄放置Ansible[被控節點(managed node)](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#managed-nodes)的[設備清單(inventory)](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#inventory)檔案，包含但不限於要控制的機器的連線細節以及機器、機器群組專屬的變數定義

Ansible支援INI與YAML兩種設備清單(inventory)的格式，建議使用結構較清晰且大規模之設備清單較易讀的YAML格式

主機與機器群組專屬的變數定義可以獨立宣告於設備清單檔案之外，細節請參閱子目錄下之host_vars與group_vars目錄的說明文件

除上述所謂的靜態設備清單(static inventory)外，Ansible 另外支援自外部程式取得設備清單（稱為動態設備清單(dynamic inventory)），使用方式請參閱 [Working with dynamic inventory — Ansible Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html) 官方文件

如有加密 inventory 內機密訊息的需求可使用 [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) 工具

## 參考資料

* [How to build your inventory — Ansible Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
* [Deployment environment - Wikipedia](https://en.wikipedia.org/wiki/Deployment_environment#Environments)
