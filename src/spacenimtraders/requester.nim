import types
import constants
import utils

import std/httpclient
import std/httpcore
import std/asyncdispatch
import std/json
import std/uri
import std/os
import std/strformat
import std/strutils

proc newHttpClient(client: Client | AsyncClient): HttpClient | AsyncHttpClient =
    ## Create a new AsyncHttpClient with default settings
    let headers = newHttpHeaders {
        "Authorization": "Bearer " & client.token.strip(),
    }
    when client is Client:
        result = newHttpClient(userAgent = clientUserAgent)
    else:
        result = newAsyncHttpClient(userAgent = clientUserAgent)

    result.headers = headers

proc checkError(statusCode: HttpCode, responseJson: JsonNode) =
    ## Runs a check against the response and raises an apporiate exception
    if not statusCode.is2xx():
        let
            message = responseJson["error"]["message"].getStr()    
            code = responseJson["error"]["code"].getInt()
        ## TODO: Have different exceptions for the different error codes    
        raise newException(ApiError, message)

proc request*(client: Client | AsyncClient, url: string, verb: HttpMethod, reqBody: string = "", params: seq[(string, string)] = @[]): Future[Response | AsyncResponse] {.multisync.} =
    ## Make a request to the api
    # Create a new client since nim still cant reuse old sockets
    let httpClient = client.newHttpClient()
    defer: httpClient.close()
    let headers = if verb == HttpPost:
            newHttpHeaders({"Content-Type": "application/json"}, titleCase = true)
        else: 
            nil
    let fullURL = baseURL & url & "?" & params.encodeQuery()
    result = await httpClient.request(fullURL, verb, body = reqBody, headers)
    let
        body = await result.body()
        json = body.parseJson()
        
    when defined(traderDebug):
        debug(
            fmt"Making {verb} request to: {url}",
            if reqBody != "": fmt"Body: {reqBody}" else: "",
            if headers != nil: $headers else: "",
            "Got status: " & result.status,
            "Got body: " & json.pretty()
        )
        
    checkError(result.code, json)
    if (result.code == Http429):
        # Backoff for a bit and then retry
        when defined(traderDebug):
            debug("Retrying request in 2 seconds")
        when client is Client:
            sleep(550)
        else:
            await sleepAsync(550)
        result = await client.request(fullURL, verb, body, params)

proc parseJson*[T](response: Response | AsyncResponse, to: typedesc[T], accessTop: bool = true): Future[T] {.multisync.} =
    ## Parses the body of an async response in one call
    ## accessTop means to go into the top parent element first if there is only one
    let body = await response.body()
    var json = body.parseJson()
    if json.len() == 1 and accessTop:
        # TODO: Find better method of doing this
        for element in json.pairs():
            json = element.val
            break
    result = json.to(to)
