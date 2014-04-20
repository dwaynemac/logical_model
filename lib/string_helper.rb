require 'active_support/core_ext/string'

class StringHelper
  
  def self.to_class(word)
    singularize(word.to_s).camelize.constantize
  end

  # super simple singularizer
  def self.singularize(word)
    word.gsub /(.*)s/,'\1'
  end

  def self.constantize(word)
    word.constantize
  end

end
