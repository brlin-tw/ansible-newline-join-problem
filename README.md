# Ansible problem where merging newline-including string list using join filter creates string with literal newline escape sequence

A confusing problem that is quadrupled by YAML, Ansible, Python, and Jinja.

## Reference

* [Ansible Template Tester](https://ansible.sivel.net/test/)  
  Useful utility to test how a Jinja2 template renders(with Ansible-specific filters)
* [Jinja live parser](https://cryptic-cliffs-32040.herokuapp.com/)  
  Useful utility to test how a Jinja2 template renders(without Ansible-specific filters)