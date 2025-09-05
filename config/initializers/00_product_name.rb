# Centralized product naming
# Use ENV['PRODUCT_NAME'] to override without code changes.
# Product naming and header styling
Rails.application.config.x.product_name  = ENV.fetch('PRODUCT_NAME',  'tes-tec TOTA')
Rails.application.config.x.product_brand = ENV.fetch('PRODUCT_BRAND', 'tes-tec')
Rails.application.config.x.product_header = ENV.fetch('PRODUCT_HEADER', 'TOTA')
