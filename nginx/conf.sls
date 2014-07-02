{% from "nginx/map.jinja" import nginx with context %}


include:
  - nginx


# This is a state file to configure nginx. As there is a high variety of needs
# I just choose a way to organize the confs. This state file is prone to be
# forked to suit each one needs. Hopefully, as it is, should be enough for most
# needs.


{% set files_switch = salt['pillar.get']('nginx:files_switch', ['id']) %}


{{ nginx.config }}:
  file:
    - managed
    - template: jinja
    - source:
      {% for grain in files_switch if salt['grains.get'](grain) is defined -%}
      - salt://nginx/files/{{ salt['grains.get'](grain) }}/etc/nginx/nginx.conf.jinja
      {% endfor -%}
      - salt://nginx/files/default/etc/nginx/nginx.conf.jinja
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx


{% for site in salt['pillar.get']('nginx:sites', []) %}

{% set site_attr = salt['pillar.get']('nginx:sites:' ~ site) %}

  {% if site_attr['conf_filename'] is defined %}
    {% set conf_filename = site_attr['conf_filename'] %}
  {% else %}
    {% set conf_filename = site ~ '.conf' %}
  {% endif %}

  {% if site_attr['template'] is defined %}
    {% set template = site_attr['template'] %}
  {% else %}
    {% set template = 'minimal' %}
  {% endif %}


  {% if site_attr['state'] is not defined or
        site_attr['state'] == 'enabled' %}
/etc/nginx/sites-available/{{ conf_filename }}:
  file:
    - managed
    - source:
      {% for grain in files_switch if salt['grains.get'](grain) is defined -%}
      - salt://nginx/files/{{ salt['grains.get'](grain) }}/etc/nginx/sites-available/{{ template }}.jinja
      {% endfor -%}
      - salt://nginx/files/default/etc/nginx/sites-available/{{ template }}.jinja
    - template: jinja
    - context:
        site: {{ site }}
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx

/etc/nginx/sites-enabled/{{ conf_filename }}:
  file:
    - symlink
    - target: /etc/nginx/sites-available/{{ conf_filename }}
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx


    {% if site_attr['create_dirs'] is defined and site_attr['create_dirs'] %}
      {% if site_attr['root'] is defined %}
{{ site_attr['root'] }}:
  file:
    - directory
    - makedirs: true
    - user: {{ site_attr['user'] | d('www-data') }}
    - group: {{ site_attr['group'] | d('www-data') }}
    - mode: 2755
    - require:
      - user: {{ site_attr['user'] | d('www-data') }}
      - group: {{ site_attr['group'] | d('www-data') }}
    - require_in:
      - service: nginx
      {% endif %}


      {% if site_attr['log_dir'] is defined %}
{{ site_attr['log_dir'] }}:
  file:
    - directory
    - makedirs: true
    - user: {{ site_attr['user'] | d('www-data') }}
    - group: {{ site_attr['group'] | d('www-data') }}
    - mode: 775
    - require:
      - user: {{ site_attr['user'] | d('www-data') }}
      - group: {{ site_attr['group'] | d('www-data') }}
    - require_in:
      - service: nginx
      {% endif %}
    {% endif %}


  {% elif site_attr['state'] == "disabled" %}
/etc/nginx/sites-enabled/{{ conf_filename }}:
  file:
    - absent
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx


  {% elif site_attr['state'] == 'absent' %}
/etc/nginx/sites-enabled/{{ conf_filename }}:
  file:
    - absent
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx


/etc/nginx/sites-available/{{ conf_filename }}:
  file:
    - absent
    - require:
      - pkg: nginx
    - watch_in:
      - service: nginx


  {% endif %}
{% endfor %}
