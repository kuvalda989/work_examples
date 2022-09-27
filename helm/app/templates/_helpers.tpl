{{- define "app.labels.static" -}}
app: {{ .Values.name }}
component: {{ .Values.name }}
release: {{ .Release.Name }}
{{- end -}}

{{- define "app.labels" -}}
{{ include "app.labels.static" $ }}
chart: {{ .Values.name }}-{{ .Chart.Version }}
version: "{{ .Values.global.release_version }}"
{{- end -}}

{{- define "env_short_name" -}}
    {{- .Release.Namespace -}}
{{- end -}}

{{- define "app.db_name" -}}
  {{- if .Values.custom_db_host_app -}}
    {{ .Values.db.db_name | replace "-" "_" -}}
  {{- else -}}
    {{- include "env_short_name" $ | replace "-" "_" -}}_{{ .Values.name | replace "-" "_" -}}
  {{- end -}}
{{- end -}}

{{- define "app.db_username" -}}
  {{- if and .Values.custom_db_host_app -}}
    {{ .Values.db.username | replace "-" "_" -}}
  {{- else -}}
    {{- include "env_short_name" $ | replace "-" "_" -}}_{{ .Values.name | replace "-" "_" -}}
  {{- end -}}
{{- end -}}

{{- define "app.db_host" -}}
  {{- if .Values.external_db -}}
    {{- .Values.db.external_svc_name -}}
  {{- else if .Values.custom_db_host_app -}}
    {{ .Values.db.db_hostname }}-postgresql
  {{- else -}}
    {{- .Values.name }}-postgresql
  {{- end -}}
{{- end -}}


{{- define "app.env_vars_base" -}}
  {{- if .Values.requires_db }}
- name: SPRING_DATASOURCE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.name }}-db-access
      key: db_password
  {{- end }}

  {{- if .Values.apigw.secret }}
- name: CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-apigw-secret
      key: secret
  {{- end }}
{{- end -}}

{{- define "app.env_vars_links" -}}
{{- range $key, $val := .Values.links }}
    {{- if $val.links_domain }}
- name: {{ $key }}
  value: {{ $val.protocol }}://{{ $val.service }}-{{ include "env_short_name" $ }}.{{ tpl (index (index $.Values.domain $val.links_domain) "url")  $ }}{{ $val.path }}
    {{- else }}
- name: {{ $key }}
  value: {{ $val.protocol }}://{{ $val.service }}-{{ include "env_short_name" $ }}.{{ tpl (index (index $.Values.domain $.Values.links_domain) "url")  $ }}{{ $val.path }}
    {{- end }}
{{- end -}}
{{- end -}}
