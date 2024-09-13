import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.text.SpannableString
import android.text.style.StyleSpan
import android.graphics.Typeface

class DatabaseManager private constructor(context: Context) {
    private var db: SQLiteDatabase? = null

    init {
        try {
            val dbPath = context.getDatabasePath("data.sqlite").absolutePath
            db = SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READONLY)
            println("Connected to database at path: $dbPath")
        } catch (e: Exception) {
            println("Unable to connect to database: ${e.message}")
        }
    }

    fun getIyals(pal: String, language: String): List<String> {
        val iyals = mutableListOf<String>()
        val palColumn = if (language == "Tamil") "பால்" else "English Title"
        val iyalColumn = if (language == "Tamil") "இயல்" else "English Heading"
        
        val query = """
            SELECT DISTINCT $iyalColumn
            FROM tirukkural
            WHERE $palColumn = ?
            ORDER BY திருக்குறள்
        """.trimIndent()

        db?.rawQuery(query, arrayOf(pal))?.use { cursor ->
            while (cursor.moveToNext()) {
                iyals.add(cursor.getString(0))
            }
        }

        return iyals
    }

    fun getAdhigarams(iyal: String, language: String): List<String> {
        val adhigarams = mutableListOf<String>()
        val iyalColumn = if (language == "Tamil") "இயல்" else "English Heading"
        val adhigaramColumn = if (language == "Tamil") "அதிகாரம்" else "English Chapter"
        
        val query = """
            SELECT DISTINCT $adhigaramColumn
            FROM tirukkural
            WHERE $iyalColumn = ?
            ORDER BY திருக்குறள்
        """.trimIndent()

        db?.rawQuery(query, arrayOf(iyal))?.use { cursor ->
            while (cursor.moveToNext()) {
                adhigarams.add(cursor.getString(0))
            }
        }

        return adhigarams
    }

    fun getSingleLine(adhigaram: String, language: String): List<String> {
        val kurals = mutableListOf<String>()
        val query = """
            SELECT திருக்குறள், $language
            FROM tirukkural
            WHERE `English Chapter` = ?
            ORDER BY திருக்குறள்
        """.trimIndent()

        db?.rawQuery(query, arrayOf(adhigaram))?.use { cursor ->
            while (cursor.moveToNext()) {
                val kuralId = cursor.getInt(0)
                val line = cursor.getString(1)
                kurals.add("$kuralId $line")
            }
        }

        return kurals
    }

    fun getFirstLine(adhigaram: String, language: String): List<List<String>> {
        val kurals = mutableListOf<List<String>>()
        val (firstLineColumn, secondLineColumn) = when (language) {
            "Tamil" -> Pair("First Line", "Second Line")
            "Telugu" -> Pair("Telugu 1", "Telugu 2")
            "Hindi" -> Pair("Hindi 1", "Hindi 2")
            else -> Pair("First Line English", "Second Line English")
        }

        val query = """
            SELECT திருக்குறள், `$firstLineColumn`, `$secondLineColumn`
            FROM tirukkural
            WHERE `English Chapter` = ?
            ORDER BY திருக்குறள்
        """.trimIndent()

        db?.rawQuery(query, arrayOf(adhigaram))?.use { cursor ->
            while (cursor.moveToNext()) {
                val kuralId = cursor.getInt(0)
                val firstLine = "${cursor.getString(1)}"
                val secondLine = cursor.getString(2)
                kurals.add(listOf("$kuralId $firstLine", secondLine))
            }
        }

        return kurals
    }

    fun getExplanation(kuralId: Int, language: String): SpannableString {
        val explanationBuilder = StringBuilder()
        val query = if (language == "Tamil") {
            """
            SELECT கலைஞர், மணக்குடவர், பரிமேலழகர், `மு. வரதராசன்`, `சாலமன் பாப்பையா`, `வீ. முனிசாமி`
            FROM tirukkural
            WHERE திருக்குறள் = ?
            """.trimIndent()
        } else {
            "SELECT Explanation FROM tirukkural WHERE திருக்குறள் = ?"
        }

        db?.rawQuery(query, arrayOf(kuralId.toString()))?.use { cursor ->
            if (cursor.moveToFirst()) {
                if (language == "Tamil") {
                    val titles = listOf("கலைஞர்", "மணக்குடவர்", "பரிமேலழகர்", "மு. வரதராசன்", "சாலமன் பாப்பையா", "வீ. முனிசாமி")
                    for (i in 0 until cursor.columnCount) {
                        explanationBuilder.append("${titles[i]}: ${cursor.getString(i)}\n\n")
                    }
                } else {
                    explanationBuilder.append(cursor.getString(0))
                }
            }
        }

        val spannableString = SpannableString(explanationBuilder.toString())
        if (language == "Tamil") {
            var startIndex = 0
            while (true) {
                val colonIndex = explanationBuilder.indexOf(": ", startIndex)
                if (colonIndex == -1) break
                spannableString.setSpan(StyleSpan(Typeface.BOLD), startIndex, colonIndex, 0)
                startIndex = explanationBuilder.indexOf("\n\n", colonIndex) + 2
            }
        }

        return spannableString
    }

    fun searchContent(query: String): List<SearchResult> {
        val results = mutableListOf<SearchResult>()
        val searchQuery = """
            SELECT திருக்குறள், `English Heading`, `English Chapter`, `First Line English`, `Second Line English`, Explanation
            FROM tirukkural
            WHERE `English Heading` LIKE ? OR `English Chapter` LIKE ? OR `First Line English` LIKE ? OR `Second Line English` LIKE ? OR Explanation LIKE ?
            LIMIT 20
        """.trimIndent()
        val searchPattern = "%$query%"

        db?.rawQuery(searchQuery, Array(5) { searchPattern })?.use { cursor ->
            while (cursor.moveToNext()) {
                val result = SearchResult(
                    kuralId = cursor.getInt(0),
                    heading = cursor.getString(1),
                    subheading = cursor.getString(2),
                    content = "${cursor.getString(3)}\n${cursor.getString(4)}",
                    explanation = cursor.getString(5)
                )
                results.add(result)
            }
        }

        return results
    }

    companion object {
        @Volatile
        private var instance: DatabaseManager? = null

        fun getInstance(context: Context): DatabaseManager {
            return instance ?: synchronized(this) {
                instance ?: DatabaseManager(context).also { instance = it }
            }
        }
    }
}

data class SearchResult(
    val kuralId: Int,
    val heading: String,
    val subheading: String,
    val content: String,
    val explanation: String
)