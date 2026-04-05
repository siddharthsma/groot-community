package main

type connectionConfig struct {
	APIKey string `json:"api_key"`
}

type pingParams struct {
	Message string `json:"message"`
}
