
class ModelBase

  CLASS_DB = {'User' => 'users', 'Question' => 'questions', 'Reply' => 'replies'}

  attr_accessor :id

  def initialize(options)
    @id = options['id']
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{CLASS_DB[self.to_s]}
      WHERE
        id = ?
    SQL
    return nil if data.empty?
    self.new(data.first)
  end

end
