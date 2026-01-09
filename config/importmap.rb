pin 'application-spree-redirections', to: 'spree_redirections/application.js', preload: false

pin_all_from SpreeRedirections::Engine.root.join('app/javascript/spree_redirections/controllers'),
             under: 'spree_redirections/controllers',
             to:    'spree_redirections/controllers',
             preload: 'application-spree-redirections'
