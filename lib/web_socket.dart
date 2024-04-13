String webSocketInjection(Uri url){
  return '''
<script type="application/javascript">
    let hotReloadSocket = null;
    const initHotReloadSocket = function (shouldReload) {
            console.log('Connecting to socket at $url');
        hotReloadSocket = new WebSocket('$url');
        hotReloadSocket.onmessage = function (event) {
            if (event.data === 'reload') {
                console.log("reloading");
                hotReloadSocket.close();
                window.location.reload();
            }
        };
        hotReloadSocket.onopen = function (event) {
            if (shouldReload) {
                window.location.reload();
            }
        };
        hotReloadSocket.onclose = function (event) {
            setTimeout(function () {
                initHotReloadSocket(true);
            }, 1000);
        };
    };
    initHotReloadSocket(false);
</script>
''';
}