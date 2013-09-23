isLoadingBarInjected = (doc) ->
  injected = false
  divs = angular.element(doc).find('div')
  for i in divs
    if angular.element(i).attr('id') is 'loading-bar'
      injected = true
      break
  return injected

describe 'loadingBarInterceptor Service', ->

  $http = $httpBackend = $document = $timeout = result = loadingBar = null
  response = {message:'OK'}
  endpoint = '/service'

  beforeEach ->
    module 'chieffancypants.loadingBar', (cfpLoadingBarProvider) ->
      loadingBar = cfpLoadingBarProvider
      return

    result = null
    inject (_$http_, _$httpBackend_, _$document_, _$timeout_) ->
      $http = _$http_
      $httpBackend = _$httpBackend_
      $document = _$document_
      $timeout = _$timeout_

  beforeEach ->
    this.addMatchers
      toBeBetween: (high, low) ->
        if low > high
          temp = low
          low = high
          high = temp
        return this.actual > low && this.actual < high


  afterEach ->
    $httpBackend.verifyNoOutstandingRequest()
    $timeout.verifyNoPendingTasks()


  it 'should not increment if the response is cached in a cacheFactory', inject (cfpLoadingBar, $cacheFactory) ->
    cache = $cacheFactory('loading-bar')
    $httpBackend.expectGET(endpoint).respond response
    $http.get(endpoint, cache: cache).then (data) ->
      result = data

    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.flush(1)
    expect(cfpLoadingBar.status()).toBe 1
    cfpLoadingBar.complete() # set as complete
    $timeout.flush()

    $http.get(endpoint, cache: cache).then (data) ->
      result = data
    # no need to flush $httpBackend since the response is cached
    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.verifyNoOutstandingRequest()
    $timeout.flush() # loading bar is animated, so flush timeout


  it 'should not increment if the response is cached using $http.defaults.cache', inject (cfpLoadingBar, $cacheFactory) ->
    $http.defaults.cache = $cacheFactory('loading-bar')
    $httpBackend.expectGET(endpoint).respond response
    $http.get(endpoint).then (data) ->
      result = data

    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.flush(1)
    expect(cfpLoadingBar.status()).toBe 1
    cfpLoadingBar.complete() # set as complete
    $timeout.flush()

    $http.get(endpoint).then (data) ->
      result = data
    # no need to flush $httpBackend since the response is cached
    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.verifyNoOutstandingRequest()
    $timeout.flush() # loading bar is animated, so flush timeout


  it 'should not increment if the response is cached', inject (cfpLoadingBar) ->
    $httpBackend.expectGET(endpoint).respond response
    $http.get(endpoint, cache: true).then (data) ->
      result = data

    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.flush(1)
    expect(cfpLoadingBar.status()).toBe 1
    cfpLoadingBar.complete() # set as complete
    $timeout.flush()

    $http.get(endpoint, cache: true).then (data) ->
      result = data
    # no need to flush $httpBackend since the response is cached
    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.verifyNoOutstandingRequest()
    $timeout.flush() # loading bar is animated, so flush timeout


  it 'should increment the loading bar when not all requests have been recieved', inject (cfpLoadingBar) ->
    $httpBackend.expectGET(endpoint).respond response
    $httpBackend.expectGET(endpoint).respond response
    $http.get(endpoint).then (data) ->
      result = data
    $http.get(endpoint).then (data) ->
      result = data

    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.flush(1)
    expect(cfpLoadingBar.status()).toBe 0.5

    $httpBackend.flush()
    expect(cfpLoadingBar.status()).toBe 1
    $httpBackend.verifyNoOutstandingRequest()
    $timeout.flush() # loading bar is animated, so flush timeout


  it 'should count http errors as responses so the loading bar can complete', inject (cfpLoadingBar) ->
    # $httpBackend.expectGET(endpoint).respond response
    $httpBackend.expectGET(endpoint).respond 401
    $httpBackend.expectGET(endpoint).respond 401
    $http.get(endpoint)
    $http.get(endpoint)

    expect(cfpLoadingBar.status()).toBe 0
    $httpBackend.flush(1)
    expect(cfpLoadingBar.status()).toBe 0.5
    $httpBackend.flush()
    expect(cfpLoadingBar.status()).toBe 1

    $httpBackend.verifyNoOutstandingRequest()
    $timeout.flush()



  it 'should insert the loadingbar into the DOM when a request is sent', ->
    $httpBackend.expectGET(endpoint).respond response
    $httpBackend.expectGET(endpoint).respond response
    $http.get(endpoint)
    $http.get(endpoint)

    $httpBackend.flush(1)
    divs = angular.element($document[0].body).find('div')

    injected = isLoadingBarInjected $document[0].body

    expect(injected).toBe true
    $httpBackend.flush()
    $timeout.flush()


  it 'should remove the loading bar when all requests have been received', ->
    $httpBackend.expectGET(endpoint).respond response
    $httpBackend.expectGET(endpoint).respond response
    $http.get(endpoint)
    $http.get(endpoint)

    $timeout.flush() # loading bar is animated, so flush timeout
    expect(isLoadingBarInjected($document[0].body)).toBe true

    $httpBackend.flush()
    $timeout.flush()

    expect(isLoadingBarInjected($document[0].body)).toBe false

  it 'should get and set status', inject (cfpLoadingBar) ->
    cfpLoadingBar.start()
    $timeout.flush()

    cfpLoadingBar.set(0.4)
    expect(cfpLoadingBar.status()).toBe 0.4

    cfpLoadingBar.set(0.9)
    expect(cfpLoadingBar.status()).toBe 0.9


    cfpLoadingBar.complete()
    $timeout.flush()

  it 'should increment things randomly', inject (cfpLoadingBar) ->
    cfpLoadingBar.start()
    $timeout.flush()

    # increments between 3 - 6%
    cfpLoadingBar.set(0.1)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBeBetween(3, 6)

    cfpLoadingBar.set(0.2)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBeBetween(3, 6)

    # increments between 0 - 3%
    cfpLoadingBar.set(0.25)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBeBetween(0, 3)

    cfpLoadingBar.set(0.5)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBeBetween(0, 3)

    # increments between 0 - 2%
    cfpLoadingBar.set(0.65)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBeBetween(0, 2)

    cfpLoadingBar.set(0.75)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBeBetween(0, 2)

    # increments 0.5%
    cfpLoadingBar.set(0.9)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBe 0.5

    cfpLoadingBar.set(0.97)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBeGreaterThan width
    expect(width2 - width).toBe 0.5

    # stops incrementing:
    cfpLoadingBar.set(0.99)
    lbar = angular.element(document.getElementById('loading-bar'))
    width = lbar.children().css('width').slice(0, -1)
    $timeout.flush()
    width2 = lbar.children().css('width').slice(0, -1)
    expect(width2).toBe width


    cfpLoadingBar.complete()
    $timeout.flush()


  it 'should not set the status if the loading bar has not yet been started', inject (cfpLoadingBar) ->
    cfpLoadingBar.set(0.5)
    expect(cfpLoadingBar.status()).toBe 0
    cfpLoadingBar.set(0.3)
    expect(cfpLoadingBar.status()).toBe 0

    cfpLoadingBar.start()
    cfpLoadingBar.set(0.3)
    expect(cfpLoadingBar.status()).toBe 0.3

    cfpLoadingBar.complete()
    $timeout.flush()

  it 'should hide the spinner if configured', inject (cfpLoadingBar) ->
    # verify it works by default:
    cfpLoadingBar.start()
    spinner = document.getElementById('loading-bar-spinner')
    expect(spinner).not.toBeNull()
    cfpLoadingBar.complete()
    $timeout.flush()

    # now configure it to not be injected:
    cfpLoadingBar.includeSpinner = false
    cfpLoadingBar.start()
    spinner = document.getElementById('loading-bar-spinner')
    expect(spinner).toBeNull
    cfpLoadingBar.complete()
    $timeout.flush()

