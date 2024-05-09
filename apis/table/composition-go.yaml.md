---
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: table.dynamodb.aws.platform.upbound.io
  labels:
    provider: aws
spec:
  compositeTypeRef:
    apiVersion: dynamodb.aws.platform.upbound.io/v1alpha1
    kind: XTable

  mode: Pipeline
  pipeline:
    - step: go-templating
      functionRef:
        name: crossplane-contrib-function-go-templating
      input:
        apiVersion: gotemplating.fn.crossplane.io/v1beta1
        kind: Resources
        source: Inline
        inline:
        template: |
          {{ $spec := .observed.composite.resource.spec }}
          {{ $status := .observed.composite.resource.status }}
          ---
          apiVersion: dynamodb.aws.upbound.io/v1beta1
          kind: Table
          metadata:
            annotations:
              {{ setResourceNameAnnotation (print "table") }}
          spec:
            deletionPolicy: {{ $spec.parameters.deletionPolicy }}
            forProvider:
              region: {{ $spec.parameters.region }}
              attribute: {{ $spec.parameters.attribute | toYaml | nindent 4 }}
              globalSecondaryIndex: {{ $spec.parameters.globalSecondaryIndex | toYaml | nindent 4 }}
              tags: {{ $spec.parameters.tags | toYaml | nindent 4 }}
              hashKey: {{ $spec.parameters.hashKey }}
              rangeKey: {{ $spec.parameters.rangeKey }}
              {{- if $spec.parameters.tableReplica }}
              billingMode: {{ $spec.parameters.billingMode }}
              {{- else }}
              billingMode: PROVISIONED
              readCapacity: {{ $spec.parameters.readCapacity }}
              writeCapacity: {{ $spec.parameters.writeCapacity }}
              {{- end }}
            providerConfigRef.name: {{ $spec.parameters.providerConfigName }}
          status.dynamodbTable: {{ $status.atProvider }}

    - step: automatically-detect-ready-composed-resources
      functionRef:
        name: crossplane-contrib-function-auto-ready
