{% set db_url = salt.pillar.get('hookforward:db_url') -%}
{% set notify_url = salt.pillar.get('hookforward:notify_url') -%}

curl:
  pkg.latest

nodejs_pkg:
  pkg.installed:
    - name: nodejs

node_link:
  file.symlink:
    - name: /usr/bin/node
    - target: /usr/bin/nodejs
    - require:
      - pkg: curl
      - pkg: nodejs

npm:
  pkg.installed

hookforward:
  npm.installed:
    - require:
      - pkg: npm

{%  if db_url and notify_url -%}
setup:
  file.managed:
    - name: /etc/systemd/system/hookforward.service
    - template: jinja
    - source: salt://hookforward/hookforward.service.tmpl
    - require:
      - npm: hookforward
    - context:
      db_url: {{ db_url }}
      notify_url: {{ notify_url }}
  cmd.run:
    - name: systemctl daemon-reload
  service.running:
    - name: hookforward
    - enable: True
    - restart: True
{%- else %}
teardown:
  file.absent:
    - name: /etc/systemd/system/hookforward.service
  cmd.run:
    - name: systemctl daemon-reload
{%  if salt.service.available('hookforward') -%}
  service.dead:
    - name: hookforward
    - enable: False
{%- endif %}
{%- endif %}
