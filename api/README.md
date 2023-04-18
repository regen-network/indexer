# analytics/api

## Chain

Query chain by chain id:

```
/chain/{chain_id}
```

### Method

- GET

### Parameters

- `chain_id` is the chain id.

### Returns

```json
{
  "num": 0,
  "chain_id": "regen-local"
}
```

## Errors

If any errors are encountered, the endpoint will return the following:

```json
{
    "error": "some error message"
}
```
