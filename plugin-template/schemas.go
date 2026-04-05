package main

import "encoding/json"

var pingParamsSchema = json.RawMessage(`{
  "type": "object",
  "properties": {
    "message": {
      "type": "string",
      "description": "Optional message to return from the sample operation."
    }
  }
}`)

var pingResultSchema = json.RawMessage(`{
  "type": "object",
  "properties": {
    "message": { "type": "string" },
    "status": { "type": "string" },
    "config": {
      "type": "object",
      "properties": {
        "api_key_present": { "type": "boolean" }
      }
    }
  }
}`)
