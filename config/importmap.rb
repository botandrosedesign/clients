with_options preload: true do
  pin "application"
  pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.1.3-2/app/assets/javascripts/rails-ujs.esm.js"
  pin "@hotwired/turbo-rails", to: "turbo.min.js"
  pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js"
  pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
  pin "stimulus-use-actions", to: "https://ga.jspm.io/npm:stimulus-use-actions@0.1.0/index.js"
  pin "stimulus-shorthand", to: "https://ga.jspm.io/npm:stimulus-shorthand@0.1.0/index.js"
  pin_all_from "app/javascript/controllers", under: "controllers"

  pin "bard-file", to: "bard-file.js"
  pin "sortablejs", to: "https://ga.jspm.io/npm:sortablejs@1.15.2/modular/sortable.esm.js"
  pin "rails-request-json", to: "https://ga.jspm.io/npm:rails-request-json@0.1.3/index.js"
  pin "@rails/request.js", to: "https://ga.jspm.io/npm:@rails/request.js@0.0.6/src/index.js"

  pin "tributejs", to: "https://ga.jspm.io/npm:tributejs@5.1.3/dist/tribute.min.js"

  pin "stimulus-textarea-autogrow", to: "https://ga.jspm.io/npm:stimulus-textarea-autogrow@4.1.0/dist/stimulus-textarea-autogrow.mjs"

  pin "js-cookie", to: "https://ga.jspm.io/npm:js-cookie@3.0.5/dist/js.cookie.mjs"

  pin "@github/relative-time-element", to: "https://ga.jspm.io/npm:@github/relative-time-element@4.4.2/dist/index.js"
end
