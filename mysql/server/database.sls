{%- from "mysql/map.jinja" import server, mysql_connection_args with context %}

{%- if not grains.get('noservices', False) %}
{%- for database_name, database in server.get('database', {}).iteritems() %}

mysql_database_{{ database_name }}:
  mysql_database.present:
  - name: {{ database_name }}
  - connection_user: {{ mysql_connection_args.user }}
  - connection_pass: {{ mysql_connection_args.password }}
  - connection_charset: {{ mysql_connection_args.charset }}
  - connection_host: {{ mysql_connection_args.host }}

{%- for user in database.users %}

mysql_user_{{ user.name }}_{{ database_name }}_{{ user.host }}:
  mysql_user.present:
  - host: '{{ user.host }}'
  - name: '{{ user.name }}'
  {%- if user.password is defined %}
  - password: {{ user.password }}
  {%- else %}
  - allow_passwordless: true
  {%- endif %}
  - connection_user: {{ mysql_connection_args.user }}
  - connection_pass: {{ mysql_connection_args.password }}
  - connection_charset: {{ mysql_connection_args.charset }}
  - connection_host: {{ mysql_connection_args.host }}

mysql_grants_{{ user.name }}_{{ database_name }}_{{ user.host }}:
  mysql_grants.present:
  - grant: {{ user.rights }}
  - database: '{{ database_name }}.*'
  - user: '{{ user.name }}'
  - host: '{{ user.host }}'
  - connection_user: {{ mysql_connection_args.user }}
  - connection_pass: {{ mysql_connection_args.password }}
  - connection_charset: {{ mysql_connection_args.charset }}
  - connection_host: {{ mysql_connection_args.host }}
  - require:
    - mysql_user: mysql_user_{{ user.name }}_{{ database_name }}_{{ user.host }}
    - mysql_database: mysql_database_{{ database_name }}

{%- endfor %}

{%- if database.initial_data is defined %}

/root/mysql/scripts/restore_{{ database_name }}.sh:
  file.managed:
  - source: salt://mysql/conf/restore.sh
  - mode: 770
  - template: jinja
  - defaults:
    database_name: {{ database_name }}
  - require:
    - file: mysql_dirs
    - mysql_database: mysql_database_{{ database_name }}

restore_mysql_database_{{ database_name }}:
  cmd.run:
  - name: /root/mysql/scripts/restore_{{ database_name }}.sh
  - unless: "[ -f /root/mysql/flags/{{ database_name }}-installed ]"
  - cwd: /root
  - require:
    - file: /root/mysql/scripts/restore_{{ database_name }}.sh

{%- endif %}

{%- endfor %}

{%- for user in server.get('users', []) %}

mysql_user_{{ user.name }}_{{ user.host }}:
  mysql_user.present:
  - host: '{{ user.host }}'
  - name: '{{ user.name }}'
  {%- if user.password is defined %}
  - password: {{ user.password }}
  {%- else %}
  - allow_passwordless: True
  {%- endif %}

{%- endfor %}
{%- endif %}
