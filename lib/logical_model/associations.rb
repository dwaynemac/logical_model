require 'logical_model/associations/has_many_keys'
require 'logical_model/associations/belongs_to'

class LogicalModel
  module Associations
    def self.included(base)
      base.send :include, LogicalModel::Associations::HasManyKeys
      base.send :include, LogicalModel::Associations::BelongsTo
    end
  end
end