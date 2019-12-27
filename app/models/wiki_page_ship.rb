class WikiPageShip < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :wiki_page

  validates_uniqueness_of :wiki_page_id, :scope => [:target_type, :target_id]

  USAGES = [
    { :value => 0, alias: 'document' }, # 未归类文档
    { :value => 1, alias: 'requirement_document' }, # 需求文档
    { :value => 2, alias: 'technical_document' }, # 技术文档
    { :value => 3, alias: 'deploy_document' }, # 部署文档
    { :value => 4, alias: 'user_document' }, # 用户文档
  ]
end
