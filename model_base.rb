
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

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM #{CLASS_DB[self.to_s]}")
    data.map { |datum| self.new(datum) }
  end


  def save
    vars = self.instance_variables.drop(1)
    vars_joined = vars.join(", ")
    vars_joined_q = vars.join(" = ?, ") + " = ?"
    question_marks = (["?"] * vars.count).join(", ")
    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, *vars)
        INSERT INTO
          #{CLASS_DB[self.to_s]} (#{vars_joined})
        VALUES
          (#{question_marks})
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, *vars, @id)
        UPDATE
          #{CLASS_DB[self.to_s]}
        SET
          #{vars_joined_q}
        WHERE
          id = ?
      SQL
    end
  end

end
