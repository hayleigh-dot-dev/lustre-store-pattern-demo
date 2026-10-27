# codebeam26

This is a quick demo of the "store pattern" I presented at Code BEAM '26. 

In development it's convenient to have the client app and the server running
independently, so you can use Lustre's dev tools for clientside development. To
make things work in that context you can see in the client app's `gleam.toml` we
are telling lustre-dev-tools that the body of the HTML should look like:

```html
<lustre-server-component
  route="/ws/store" 
  provides="time count">
  <div id="app"></div>
</lustre-server-component>
```

Notices the `provides` attribute. This is super important, forgetting this will
mean things won't work!

The client subscribes to both contexts. It has buttons for incrementing and
decrementing the count. When they're clicked they don't modify the client
model directly, instead they dispatch events.

The server component handles those events and updates its model + provides the
new counts. The demo is set up so a single server component instance is shared
across all clients, so incrementing the count in one tab will also show up in
any others you have open.

## To run

In two separate terminal windows run:

```sh
gleam run
```

and

```sh
cd app && gleam run -m lustre/dev start
```

The server runs on port 3000 and the client app is served on port 1234. We use
the dev tools' proxy to proxy both the websocket and the request for the server
component runtime bundle to the backend.# lustre-store-pattern-demo
