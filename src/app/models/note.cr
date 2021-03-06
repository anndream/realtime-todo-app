class Note

  alias AnyInteger   = Int16 | Int32 | Int64 | UInt32
  alias ListOfNotes  = Array(Hash(String, AnyInteger | String))
  alias DBConnection = PG::Connection
  alias DBResult     = PG::Result

  JSON.mapping(
    id:         { type: Int64 , nilable: true },
    title:      { type: String, nilable: true },
    content:    { type: String, nilable: true },
    created_at: { type: String, nilable: true },
    updated_at: { type: String, nilable: true }
  )

  def self.create_from(message : String) : self
    self.from_json(message)
  end

  def self.all(conn : DBConnection) : ListOfNotes
    self.transform_notes(conn.exec(%{
      SELECT
        id, title , content,
        to_char(created_at, 'DD-MM-YYYY HH24:MI:SS') as created_at,
        to_char(updated_at, 'DD-MM-YYYY HH24:MI:SS') as updated_at
      FROM notes
      ORDER BY id
    }))
  end

  def insert(conn : DBConnection) : DBResult
    conn.exec(%{
      INSERT INTO notes (title, content, created_at, updated_at)
      VALUES (
        upper(substr($1, 1, 1)) || substr($1, 2, length($1)),
        upper(substr($2, 1, 1)) || substr($2, 2, length($2)),
        current_timestamp,
        current_timestamp
      )
    }, [self.title, self.content])
  end

  def update(conn : DBConnection) : DBResult
    conn.exec(%{
      UPDATE notes
      SET title      = $1,
          content    = $2,
          updated_at = current_timestamp
      WHERE id = $3;
    }, [self.title, self.content, self.id])
  end

  def delete(conn : DBConnection) : DBResult
    conn.exec(%{
      DELETE FROM notes
      WHERE id = $1;
    }, [self.id])
  end

  def self.transform_notes(notes_table : DBResult) : ListOfNotes
    notes_table.to_hash.map do |note|
      {
        "id"         => note["id"].as(Int),
        "title"      => note["title"].as(String),
        "content"    => note["content"].as(String),
        "created_at" => note["created_at"].as(String),
        "updated_at" => note["updated_at"].as(String),
      }
    end
  end
end
