Spree::Core::Engine.add_routes do
  # Add your extension routes here
  namespace :admin do
    resources :redirections, except: :show
  end
end
