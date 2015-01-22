set :without, "development staging"

role :app, %w{deploy@cms-g0-1.west.omadahealth.net}
role :app, %w{deploy@cms-g0-2.west.omadahealth.net}
role :web, %w{deploy@cms-g0-1.west.omadahealth.net}
role :web, %w{deploy@cms-g0-2.west.omadahealth.net}
