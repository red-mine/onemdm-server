# Centralized product naming
# Use ENV['PRODUCT_NAME'] to override without code changes.
Rails.application.config.x.product_name = ENV.fetch('PRODUCT_NAME', 'tes-tec TOTA')
