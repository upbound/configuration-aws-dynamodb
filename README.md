# configuration-aws-dynamodb
A configuration for AWS DynamoDB tables and related resources.
This `configuration-aws-dynamodb` optionally creates a replica
table in a different region, and an arbitrary number of
requested `tableItem` resources. It optionally supports
`ContributorInsights`.

## DynamoDB Table Without Replica

An example `examples/instance-without-replica.yaml` claim
for resources without a table replica, but with
`ContributorInsights` and 2 `tableItem` resources is as follows:

```yaml
apiVersion: dynamodb.aws.platform.upbound.io/v1alpha1
kind: Instance
metadata:
  name: ddb-without-replica
spec:
  parameters:
    region: us-west-1
    # Conditionally Offer Contributor Insights
    contributorInsights: true
    # Conditionally Offer Table Replica
    tableReplica: false
    # capacity can not be set when billing_mode is "PAY_PER_REQUEST"
    readCapacity: 10
    writeCapacity: 10
    # Billing Mode is PROVISIONED or
    # PAY_PER_REQUEST (required for replication unless autoscaling is
    # configured)
    billingMode: PROVISIONED
    attribute:
      - name: UserId
        type: "S"
      - name: GameTitle
        type: "S"
      - name: TopScore
        type: "N"
    globalSecondaryIndex:
      - hashKey: GameTitle
        name: GameTitleIndex
        nonKeyAttributes:
          - UserId
        projectionType: INCLUDE
        rangeKey: TopScore
        readCapacity: 10
        writeCapacity: 10
    hashKey: UserId
    rangeKey: GameTitle
    tableItems:
      - item: >-
          '{
            "UserId": {"S": "user01"},
            "GameTitle": {"S": "Robot Quest"},
            "TopScore": {"N": "123457"}
          }'
      - item: >-
          '{
            "UserId": {"S": "user02"},
            "GameTitle": {"S": "Rocket League"},
            "TopScore": {"N": "123456"}
          }'
    tags:
      Environment: production
      Name: ddb-without-replica-1
```

The corresponding `crossplane beta trace` resources are as follows:

```shell
NAME                                                        SYNCED   READY   STATUS
Instance/ddb-without-replica (default)                      True     True    Available
└─ XInstance/ddb-without-replica-7bssl                      True     True    Available
   ├─ XTableItemSet/ddb-without-replica-7bssl-86dnv         True     True    Available
   │  ├─ TableItem/ddb-without-replica-7bssl-lnwbx          True     True    Available
   │  └─ TableItem/ddb-without-replica-7bssl-w898j          True     True    Available
   ├─ XTable/ddb-without-replica-7bssl-p6r2c                True     True    Available
   │  └─ Table/ddb-without-replica-7bssl-5x966              True     True    Available
   └─ ContributorInsights/ddb-without-replica-7bssl-ggsq2   True     True    Available
```

## DynamoDB Table With Replica

An example `examples/instance-with-replica.yaml` claim
for resources with a table replica in a different region and
`ContributorInsights`, and 2 `tableItem` resources is shown below.

Note, that it can take AWS about 18 minutes to create the replica.

```yaml
apiVersion: dynamodb.aws.platform.upbound.io/v1alpha1
kind: Instance
metadata:
  name: ddb-with-replica
spec:
  parameters:
    region: us-west-1
    # Conditionally Offer Contributor Insights
    contributorInsights: true
    # Conditionally Offer Table Replica
    tableReplica: true
    tableReplicaRegion: us-east-1
    # Billing Mode is PROVISIONED or
    # PAY_PER_REQUEST (required for replication unless autoscaling is
    # configured)
    # Capacity can not be set when billing_mode is "PAY_PER_REQUEST"
    billingMode: "PAY_PER_REQUEST"
    attribute:
      - name: UserId
        type: "S"
      - name: GameTitle
        type: "S"
      - name: TopScore
        type: "N"
    globalSecondaryIndex:
      - hashKey: GameTitle
        name: GameTitleIndex
        nonKeyAttributes:
          - UserId
        projectionType: INCLUDE
        rangeKey: TopScore
        readCapacity: 10
        writeCapacity: 10
    hashKey: UserId
    rangeKey: GameTitle
    tableItems:
      - item: >-
          '{
            "UserId": {"S": "user01"},
            "GameTitle": {"S": "Robot Quest"},
            "TopScore": {"N": "123457"}
          }'
      - item: >-
          '{
            "UserId": {"S": "user02"},
            "GameTitle": {"S": "Rocket League"},
            "TopScore": {"N": "123456"}
          }'
    tags:
      Environment: production
      Name: ddb-with-replica-1
```

The corresponding `crossplane beta trace` resources are as follows:

```shell
NAME                                                     SYNCED   READY   STATUS
Instance/ddb-with-replica (default)                      True     True    Available
└─ XInstance/ddb-with-replica-fms4w                      True     True    Available
   ├─ XTableItemSet/ddb-with-replica-fms4w-n6t4f         True     True    Available
   │  ├─ TableItem/ddb-with-replica-fms4w-jmchl          True     True    Available
   │  └─ TableItem/ddb-with-replica-fms4w-ztmjg          True     True    Available
   ├─ XTable/ddb-with-replica-fms4w-v62p2                True     True    Available
   │  ├─ TableReplica/ddb-with-replica-fms4w-m2dvr       True     True    Available
   │  └─ Table/ddb-with-replica-fms4w-49s7x              True     True    Available
   └─ ContributorInsights/ddb-with-replica-fms4w-7vslb   True     True    Available
```

## Tests

Prior to running end to end tests with `make e2e`, configure an
`UPTEST_CLOUD_CREDENTIALS` environment variable with the contents of
your AWS config credentials file. It will need an AWS access key id,
an AWS secret access key, and depending on your setup am AWS session token.
