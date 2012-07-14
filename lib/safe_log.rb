module SafeLog

  # Filters api_key
  # @return [String]
  def mask_api_key(str)
    if use_api_key
      str = str.gsub(api_key,'[SECRET]')
    end
    str
  end
end