import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectMustache

let server = HTTPServer()
server.serverPort = 8080
server.documentRoot = "webroot"

var routes = Routes()

struct MustacheHelper: MustachePageHandler {
    var values: MustacheEvaluationContext.MapType
    func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
        contxt.extendValues(with: values)
        do {
            try contxt.requestCompleted(withCollector: collector)
        } catch  {
            let reponse = contxt.webResponse
            reponse.appendBody(string: "\(error)")
                    .completed(status: HTTPResponseStatus.internalServerError)
        }
    }
}

func helloMustache(request: HTTPRequest, response: HTTPResponse) {
    var values = MustacheEvaluationContext.MapType()
    values["name"] = "Khoa"
    mustacheRequest(request: request, response: response, handler: MustacheHelper(values: values), templatePath: request.documentRoot + "/hello.mustache")
}
func helloMustache2(request: HTTPRequest, response: HTTPResponse) {
    guard let name = request.urlVariables["name"] else {
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    var values = MustacheEvaluationContext.MapType()
    values["name"] = name
    mustacheRequest(request: request, response: response, handler: MustacheHelper(values: values), templatePath: request.documentRoot + "/hello.mustache")
}
func helloMustache3(request: HTTPRequest, response: HTTPResponse) {
    var values = MustacheEvaluationContext.MapType()
    values["users"] = [
        ["name": "khoa"],
        ["name": "huy"]
    ]
    mustacheRequest(request: request, response: response, handler: MustacheHelper(values: values), templatePath: request.documentRoot + "/hello2.mustache")
}
func helloMustache4(request: HTTPRequest, response: HTTPResponse) {
    var values = MustacheEvaluationContext.MapType()
    values["users"] = [
        ["name": "khoa", "email": "khoa@gmail.com"],
        ["name": "huy", "email": "huy@gmail.com"]
    ]
    mustacheRequest(request: request, response: response, handler: MustacheHelper(values: values), templatePath: request.documentRoot + "/hello3.mustache")
}
func helloMustache5(request: HTTPRequest, response: HTTPResponse) {
    let values = MustacheEvaluationContext.MapType()
    mustacheRequest(request: request, response: response, handler: MustacheHelper(values: values), templatePath: request.documentRoot + "/hello3.mustache")
}

func returnJson(message: String, response: HTTPResponse) {
    do {
        try response.setBody(json: ["message": message])
        .setHeader(HTTPResponseHeader.Name.contentType, value: "application/json")
        .completed()
    } catch {
        response.setBody(string: "Error: \(error)")
        .completed(status: HTTPResponseStatus.internalServerError)
    }
}

routes.add(method: .get, uri: "/helloMustache", handler: helloMustache)
routes.add(method: .get, uri: "/helloMustache2/{name}", handler: helloMustache2)
routes.add(method: .get, uri: "/helloMustache3", handler: helloMustache3)
routes.add(method: .get, uri: "/helloMustache4", handler: helloMustache4)
routes.add(method: .get, uri: "/helloMustache5", handler: helloMustache5)

routes.add(method: .get, uri: "/") { (request, response) in
    response.setBody(string: "Hello server!")
    .completed()
}

routes.add(method: HTTPMethod.get, uri: "/getSample") { (request, response) in
    returnJson(message: "Hello, Khoa", response: response)
}

routes.add(method: HTTPMethod.get, uri: "/setName/{name}") { (request, response) in
    guard let name = request.urlVariables["name"] else {
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    returnJson(message: "Hello, \(name)", response: response)
}

routes.add(method: .post, uri: "post") { (request, response) in
    guard let name = request.param(name: "name") else {
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    returnJson(message: "Hello, \(name)", response: response)
}


server.addRoutes(routes)

do {
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("error \(err): \(msg)")
}
