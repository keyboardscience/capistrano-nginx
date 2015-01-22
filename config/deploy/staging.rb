set :without, "development production"

role :app, %w{deploy@54.149.215.124}
role :web, %w{deploy@54.149.215.124}
role :db, %w{deploy@54.149.215.124}
