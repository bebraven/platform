# Open the class and prepend our module to intercept calls to :execute so
# we can trace / log them.
require 'restclient_instrumentation'
require 'restclient'
module RestClient
   class Request
     prepend RestClientInstrumentation
   end
end 


