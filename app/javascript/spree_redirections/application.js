import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'

let application

if (typeof window.Stimulus === "undefined") {
  application = Application.start()
  application.debug = false
  window.Stimulus = application
} else {
  application = window.Stimulus
}

import SpreeRedirectionsController from 'spree_redirections/controllers/spree_redirections_controller' 

application.register('spree_redirections', SpreeRedirectionsController)