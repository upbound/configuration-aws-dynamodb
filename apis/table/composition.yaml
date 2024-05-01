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
    - step: patch-and-transform
      functionRef:
        name: crossplane-contrib-function-patch-and-transform
      input:
        apiVersion: gotemplating.fn.crossplane.io/v1beta1
        kind: Resources
        patchSets:
          - name: common-parameters
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.providerConfigName
                toFieldPath: spec.providerConfigRef.name
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.deletionPolicy
                toFieldPath: spec.deletionPolicy
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.region
                toFieldPath: spec.forProvider.region
        resources:
          - name: table
            base:
              apiVersion: dynamodb.aws.upbound.io/v1beta1
              kind: Table
            patches:
              - type: PatchSet
                patchSetName: common-parameters
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.globalSecondaryIndex
                toFieldPath: spec.forProvider.globalSecondaryIndex
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.attribute
                toFieldPath: spec.forProvider.attribute
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.billingMode
                toFieldPath: spec.forProvider.billingMode
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.readCapacity
                toFieldPath: spec.forProvider.readCapacity
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.writeCapacity
                toFieldPath: spec.forProvider.writeCapacity
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.hashKey
                toFieldPath: spec.forProvider.hashKey
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.rangeKey
                toFieldPath: spec.forProvider.rangeKey
              - type: FromCompositeFieldPath
                fromFieldPath: spec.parameters.tags
                toFieldPath: spec.forProvider.tags
              - type: ToCompositeFieldPath
                fromFieldPath: status.atProvider
                toFieldPath: status.dynamodbTable
