{{/*
Expand the name of the chart.
*/}}
{{- define "gbase.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gbase.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gbase.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gbase.labels" -}}
helm.sh/chart: {{ include "gbase.chart" . }}
{{ include "gbase.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gbase.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gbase.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gbase.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "gbase.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Generate scripts configmap
*/}}
{{- define "gbase.extend.scripts" -}}
{{- range $path, $_ :=  $.Files.Glob "scripts/**" }}
{{ $path | base }}: |-
{{- $.Files.Get $path | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate config configmap
*/}}
{{- define "gbase.extend.config" -}}
{{- range $path, $_ :=  $.Files.Glob "config/**" }}
{{ $path | base }}: |-
{{- $.Files.Get $path | nindent 2 }}
{{- end }}
{{- end }}


{{/*
Backup Tool image
*/}}
{{- define "gbase.bakcupToolImage" -}}
{{ .Values.image.registry | default "docker.io" }}/{{ .Values.image.gbase.repository }}:{{ .Values.image.gbase.tag }} 
{{- end }}


{{/*
distribution node cmpd spec template 
*/}}
{{- define "gbase.distribution.cmpd.spec" -}}
provider: kubeblocks.io
serviceKind: gbase
serviceVersion: 5.0.0
configs:
  - name: gbase-config
    templateRef: {{ include "gbase.cmConfigName" . }}
    namespace: {{ .Release.Namespace }}
    volumeName: gbase-config
    defaultMode: 0444
scripts:
  - name: gbase-scripts
    templateRef: {{ include "gbase.cmScriptsName" . }}
    namespace: {{ .Release.Namespace }}
    volumeName: scripts
    defaultMode: 0555 
updateStrategy: Parallel
podManagementPolicy: Parallel
{{ include "gbase.distribution.cmpd.runtime" . }}
{{- end }}


{{- define "gbase.distribution.cmpd.runtime" -}}
runtime:
  containers:
    - name: gbase
      imagePullPolicy: {{ default "IfNotPresent" .Values.image.pullPolicy }}
      command: ["/usr/sbin/init"]
      lifecycle:
        postStart:
          exec:
            command: ["/scripts/start_distribution.sh"]
      securityContext:
        privileged: true
        runAsUser: 0
      volumeMounts:
        - mountPath: /config
          name: gbase-config
        - mountPath: /data
          name: data
        - name: scripts
          mountPath: /scripts
        - name: ssh-key
          mountPath: /ssh-key
          readOnly: true
{{- end }}