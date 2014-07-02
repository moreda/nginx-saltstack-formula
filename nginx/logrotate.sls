{% from "nginx/map.jinja" import nginx with context %}


# This configures the logrotate needed configurations for the log files. In
# order to be useful, you need logrotate installed and minimally configured.


{% set files_switch = salt['pillar.get']('nginx:files_switch', ['id']) %}


nginx_logrotate:
  file:
    - directory
    - name: /etc/logrotate.d


{% for site in salt['pillar.get']('nginx:sites', []) %}

  {% set site_attr = salt['pillar.get']('nginx:sites:' ~ site) %}

  {% set logrotate_filename = 'nginx-' ~ site %}

  {% if site_attr['logrotate_template'] is defined %}
    {% set template = site_attr['logrotate_template'] %}
  {% else %}
    {% set template = 'minimal' %}
  {% endif %}

  {% if site_attr['state'] is not defined or
        site_attr['state'] == 'enabled' %}
/etc/logrotate.d/{{ logrotate_filename }}:
  file:
    - managed
    - source:
      {% for grain in files_switch if salt['grains.get'](grain) is defined -%}
      - salt://nginx/files/{{ salt['grains.get'](grain) }}/etc/logrotate.d/{{ template }}.jinja
      {% endfor -%}
      - salt://nginx/files/default/etc/logrotate.d/{{ template }}.jinja
    - template: jinja
    - context:
        site: {{ site }}
    - require:
      - pkg: nginx


  {% else %}
/etc/logrotate.d/{{ logrotate_filename }}:
  file:
    - absent
    - require:
      - pkg: nginx


  {% endif %}
{% endfor %}
