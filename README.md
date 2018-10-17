pinejs-getting-started-bug-repro
===

**THIS ISSUE IS NOW FIXED**
As of [balena-io-modules/odata-to-abstract-sql/pull/26](https://github.com/resin-io-modules/odata-to-abstract-sql/pull/26)

## 1. Rationale

When running the "getting started" example from the PineJS repro, I observed
an error when running a command which was supposed to succeed:

```
$ curl -X POST \
	-d name=testdevice \
	-d note=testnote \
	-d type=raspberry \
	http://localhost:1337/example/device

"Bind value cannot be undefined: Bind,device,id"
```

To make sure that this deviation from expectations wasn't a result of my machine
being somehow a variable, I containerized the simple app using a Dockerfile 
adapted from that used in `resin-api`, which runs a node app as a systemd service.


## 2. Observe the error

```
# builds and runs the docker container hosting the PSQL DB and the pineJS app
./build-and-run.sh

# runs the curl commands which cause the error to appear
./reproduce.sh
```

## 3. Analysis

Code reference for the below: `pinejs/src/sbvr-api/sbvr-utils.coffee#L166`

Code of interest:

```
166 exports.resolveOdataBind = resolveOdataBind = (odataBinds, value) ->
167		if _.isObject(value) and value.bind?
168			[dataType, value] = odataBinds[value.bind]
169		return value
170
171	getAndCheckBindValues = (vocab, odataBinds, bindings, values) ->
172		sqlModelTables = sqlModels[vocab].tables
173		Promise.map bindings, (binding) ->
174			if binding[0] is 'Bind'
175				if _.isArray(binding[1])
176					[tableName, fieldName] = binding[1]
177
178					referencedName = tableName + '.' + fieldName
179					value = values[referencedName]
180					if value is undefined
181						value = values[fieldName]
182
183				value = resolveOdataBind(odataBinds, value)
		...
208 	if value is undefined
209			throw new Error("Bind value cannot be undefined: #{binding}")
```

### simply put

Inside `getAndCheckBindValues()`, when `fieldname = "id"`, after the 
`_.isArray(binding[1])` block, `value` is undefined at line 208, causing the 
error to throw.

At a high level, `value` ends up undefined for `fieldname = "id"` since:

1. `"id"` is not in `request.values` (appears to be the values supplied in the 
`PUT` request)

2. although the data which corresponds to `"id"` (`1`) *is* in `request.odataBinds`,
(appears to be fallback values inferred from the OData URL?), the function
`exports.resolveOdataBind(odataBinds, value)` doesn't have the right logic to 
find that info, or isn't given a parameter in the right format.

### Detailed trace

The `bindings` param is always at *least* (that is, if we send no data with 
our PUT request):

```
"bindings":[
    [
        "Bind",
            [
                "device",
                "id"
            ]
    ]
]
```

`bindings`, as a parameter to `getAndCheckBindValues()`, comes from a `request`
object created in `pinejs/src/sbvr-api/parse-uri.coffee`. In that file,

(note: this is more like pseudocode, not actual lines)

`request.odataBinds = memoizedParseOdata(url).binds`

`request.values = requestBody.data`

So, it appears in `L178-181` try to find `device.id` or `id` among the keys 
of `values`, but it's not there. Why? Because `request.values` is simply the 
request body. `id` or `device.id` would only be there if we put them there 
after parsing the OData URL. That failing, we look it up in `request.odataBinds`.

There is therefore one big question:

The `odataBinds` object (fig 1) seems to be of the correct format to 
allow the code for `exports.resolveOdataBind(odataBinds, value)` (fig 2) to find 
the value for `fieldname = "id"`, but it wants `value` to be an object like 
(fig 3), which it won't be, since `value` will always be a string, looking at 
the format of `values`, from which it comes (fig 4)

fig 1.

```
"odataBinds": [
    [
        "Real",
        2
    ]
],
```

fig 2.

```
exports.resolveOdataBind = resolveOdataBind = (odataBinds, value) ->
	if _.isObject(value) and value.bind?
		[dataType, value] = odataBinds[value.bind]
	return value
```

fig 3.

```
{
    ...
    "bind": 0,
}
```

fig 4.

```
"values":{
    "name":"testdevice",
    "note":"updatednote",
    "type":"raspberry"
},
```





