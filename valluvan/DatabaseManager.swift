import Foundation
import SQLite // Make sure this import is correct
import UIKit // Add this import for NSAttributedString

public struct DatabaseSearchResult: Identifiable {
    public let id: Int
    public let heading: String
    public let subheading: String
    public let content: String
    public let explanation: String
    public let kuralId: Int
    
    public init(heading: String, subheading: String, content: String, explanation: String, kuralId: Int) {
        self.id = kuralId // Use kuralId as the unique identifier
        self.heading = heading
        self.subheading = subheading
        self.content = content
        self.explanation = explanation
        self.kuralId = kuralId
    }
}

public class DatabaseManager {
    public static let shared = DatabaseManager()
    private var db: Connection?
    
    private init() {
        do {
            if let path = Bundle.main.path(forResource: "data", ofType: "sqlite") {
                db = try Connection(path)
                print("Connected to database at path: \(path)") 
            } else {
                print("Database file not found in the main bundle.")
                print("Searched for 'data.sqlite' in: \(Bundle.main.bundlePath)")
                
                // List contents of the bundle for debugging
                let fileManager = FileManager.default
                if let enumerator = fileManager.enumerator(atPath: Bundle.main.bundlePath) {
                    print("Contents of the main bundle:")
                    while let filePath = enumerator.nextObject() as? String {
                        print(filePath)
                    }
                }
            }
        } catch {
            print("Unable to connect to database: \(error)")
        }
    }

    
    public func getIyals(for pal: String, language: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்")
        let palExpr = language == "Tamil" ? Expression<String>("பால்") : Expression<String>("English Title")
        let iyalExpr = language == "Tamil" ? Expression<String>("இயல்") : Expression<String>("English Heading")
        
        var iyals: [String] = []
        
        do {
            let query = tirukkuralTable
                .select(iyalExpr)
                .filter(palExpr == pal)
                .group(iyalExpr)
                .order(kuralId)
             
            for row in try db!.prepare(query) {
                iyals.append(row[iyalExpr])
            }
        } catch {
            print("Error fetching iyals: \(error)")
        } 
            
        return iyals
    }
 
    public func getAdhigarams(for iyal: String, language: String) -> ([String], [Int], [String]) {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்")
        let iyalExpr = language == "Tamil" ? Expression<String>("இயல்") : Expression<String>("English Heading")
        let adhigaramExpr = language == "Tamil" ? Expression<String>("அதிகாரம்") : Expression<String>("English Chapter")
        let adhigaramSongExpr = Expression<String>("அதிகாரம்") 
        var adhigarams: [String] = []
        var kuralIds: [Int] = []
        var adhigaramSongs: [String] = []
        do {
            let query = tirukkuralTable
                .select(adhigaramExpr, kuralId, adhigaramSongExpr)
                .filter(iyalExpr == iyal)
                .group(adhigaramExpr)
                .order(kuralId)
            
            for row in try db!.prepare(query) {
                adhigarams.append(row[adhigaramExpr])   
                kuralIds.append(row[kuralId])
                adhigaramSongs.append(row[adhigaramSongExpr])
            }
        } catch {
            print("Error fetching adhigarams: \(error)")
        }

        return (adhigarams, kuralIds, adhigaramSongs)
    } 

    public func getSingleLine(for adhigaram: String, language: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்") 
        let adhigaramExpr = Expression<String>("English Chapter")
        
        let firstLineExpr = Expression<String>(language) 
         
        var kurals: [String] = []
        do {
            let query = tirukkuralTable
                .select(kuralId, firstLineExpr)   
                .filter(adhigaramExpr == adhigaram)
                .order(kuralId)  

            for row in try db!.prepare(query) {
                kurals.append(String(row[kuralId]) + " " + row[firstLineExpr]) 
            }
        } catch {
            print("Error fetching first line: \(error)")
        }
        return kurals
    }

    public func getFirstLine(for adhigaram: String, language: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்") 
        let adhigaramExpr = language == "Tamil" ? Expression<String>("அதிகாரம்") : Expression<String>("English Chapter")
        
        let firstLineExpr: Expression<String>
        let secondLineExpr: Expression<String>
        
        switch language {
        case "Tamil":
            firstLineExpr = Expression<String>("First Line")
            secondLineExpr = Expression<String>("Second Line")
        case "Telugu":
            firstLineExpr = Expression<String>("Telugu 1")
            secondLineExpr = Expression<String>("Telugu 2")
        case "Hindi":
            firstLineExpr = Expression<String>("Hindi 1")
            secondLineExpr = Expression<String>("Hindi 2")
        default:
            firstLineExpr = Expression<String>("First Line English")
            secondLineExpr = Expression<String>("Second Line English")
        }
        
        var kurals: [String] = []
        do {
            let query = tirukkuralTable
                .select(kuralId, firstLineExpr, secondLineExpr)   
                .filter(adhigaramExpr == adhigaram)
                .order(kuralId)  

            for row in try db!.prepare(query) {
                kurals.append(String(row[kuralId]) + " " + row[firstLineExpr])
                kurals.append(row[secondLineExpr])
            }
        } catch {
            print("Error fetching first line: \(error)")
        }
        return kurals
    }
    
    func getExplanation(for kuralId: Int, language: String) -> NSAttributedString {
        let tirukkuralTable = Table("tirukkural")
        let kuralIdExpr = Expression<Int>("திருக்குறள்")
        let explanationExpr: Expression<String>
        let manaExplanationExpr: Expression<String>
        let pariExplanationExpr: Expression<String>
        let varaExplanationExpr: Expression<String>
        let popsExplanationExpr: Expression<String>
        let muniExplanationExpr: Expression<String>
        var query: Table
        var attributedExplanation = NSMutableAttributedString()

        switch language {
        case "Tamil":
            explanationExpr = Expression<String>("கலைஞர்")
            manaExplanationExpr = Expression<String>("மணக்குடவர்")
            pariExplanationExpr = Expression<String>("பரிமேலழகர")
            varaExplanationExpr = Expression<String>("மு. வரதராசன்")
            popsExplanationExpr = Expression<String>("சாலமன் பாப்பையா")
            muniExplanationExpr = Expression<String>("வீ. முனிசாமி")
            query = tirukkuralTable
                .select(explanationExpr, manaExplanationExpr, pariExplanationExpr, varaExplanationExpr, popsExplanationExpr, muniExplanationExpr)
                .filter(kuralIdExpr == kuralId) 
            do {                
                if let row = try db!.pluck(query) {
                    let boldAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
                    
                    appendExplanation(to: &attributedExplanation, title: "கலைஞர்: ", content: row[explanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "மணக்குடவர்: ", content: row[manaExplanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "பரிமேலழகர்: ", content: row[pariExplanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "மு. வரதராசன்: ", content: row[varaExplanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "சாலமன் பாப்பையா: ", content: row[popsExplanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "வீ. முனிசாமி: ", content: row[muniExplanationExpr], boldAttributes: boldAttributes, isLast: true)
                }
            } catch {
                print("Error fetching Tamil explanation: \(error)")
            }   
        default:
            explanationExpr = Expression<String>("Explanation") 
            do {                 
                query = tirukkuralTable
                    .select(explanationExpr)
                    .filter(kuralIdExpr == kuralId) 
                
                if let row = try db!.pluck(query) {
                    attributedExplanation = NSMutableAttributedString(string: row[explanationExpr])
                }
            } catch {
                print("Error fetching explanation: \(error)")
            } 
        }
        return attributedExplanation
    }

    private func appendExplanation(to attributedString: inout NSMutableAttributedString, title: String, content: String, boldAttributes: [NSAttributedString.Key: Any], isLast: Bool = false) {
        attributedString.append(NSAttributedString(string: title, attributes: boldAttributes))
        attributedString.append(NSAttributedString(string: content))
        if !isLast {
            attributedString.append(NSAttributedString(string: "\n\n"))
        }
    }

    func searchContent(query: String, language: String) -> [DatabaseSearchResult] {
        var results: [DatabaseSearchResult] = []
        let searchQuery: String
        let searchPattern = "%\(query)%"

        if language != "English" && language != "Telugu" && language != "Hindi" {
            searchQuery = """
                SELECT "திருக்குறள்", "English Heading", "English Chapter", "First Line English", "Second Line English", "Explanation", "\(language)"
                FROM tirukkural
                WHERE "English Heading" LIKE ? OR "English Chapter" LIKE ? OR "First Line English" LIKE ? OR "Second Line English" LIKE ? OR "Explanation" LIKE ? OR "\(language)" LIKE ?
                LIMIT 20
            """
            
            do {
                let rows = try db!.prepare(searchQuery, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern)
                for row in rows {
                    let result = DatabaseSearchResult(
                        heading: row[1] as? String ?? "",
                        subheading: row[2] as? String ?? "",
                        content: "\(row[6] as? String ?? "")\n\(row[3] as? String ?? "")\n\(row[4] as? String ?? "")",
                        explanation: row[5] as? String ?? "",
                        kuralId: Int(row[0] as? Int64 ?? 0)
                    )
                    results.append(result)
                }
            } catch {
                print("Error searching content: \(error.localizedDescription)")
            }    
        } else {
            if language == "English" {
                searchQuery = """
                    SELECT "திருக்குறள்", "English Heading", "English Chapter", "First Line English", "Second Line English", "Explanation"
                    FROM tirukkural
                    WHERE "English Heading" LIKE ? OR "English Chapter" LIKE ? OR "First Line English" LIKE ? OR "Second Line English" LIKE ? OR "Explanation" LIKE ?
                    LIMIT 20
                """
            } else {
                searchQuery = """
                    SELECT "திருக்குறள்", "English Heading", "English Chapter", "\(language) 1", "\(language) 2", "Explanation"
                    FROM tirukkural
                    WHERE "English Heading" LIKE ? OR "English Chapter" LIKE ? OR "\(language) 1" LIKE ? OR "\(language) 2" LIKE ? OR "Explanation" LIKE ?
                    LIMIT 20
                """
            }
            do {
                let rows = try db!.prepare(searchQuery, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern)
                for row in rows {
                    let result = DatabaseSearchResult(
                        heading: row[1] as? String ?? "",
                        subheading: row[2] as? String ?? "",
                        content: "\(row[3] as? String ?? "")\n\(row[4] as? String ?? "")",
                        explanation: row[5] as? String ?? "",
                        kuralId: Int(row[0] as? Int64 ?? 0)
                    )
                    results.append(result)
                }
            } catch {
                print("Error searching content: \(error.localizedDescription)")
            }
        }

        return results
    }


    func searchTamilContent(query: String) -> [DatabaseSearchResult] {
        var results: [DatabaseSearchResult] = []
        let searchQuery = """
            SELECT "திருக்குறள்", "இயல்", "அதிகாரம்", "First Line", "Second Line", "மணக்குடவர்", "பரிமேலழகர்", "மு. வரதராசன்", "கலைஞர்", "சாலமன் பாப்பையா", "வீ. முனிசாமி"
            FROM tirukkural
            WHERE "இயல்" LIKE ? OR "அதிகாரம்" LIKE ? OR "First Line" LIKE ? OR "Second Line" LIKE ? OR "மணக்குடவர்" LIKE ? OR "பரிமேலழகர்" LIKE ? OR "மு. வரதராசன்" LIKE ? OR "கலைஞர்" LIKE ? OR "சாலமன் பாப்பையா" LIKE ? OR "வீ. முனிசாமி" LIKE ?
            LIMIT 20
        """
        let searchPattern = "%\(query)%"

        do {
            let rows = try db!.prepare(searchQuery, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern)
            for row in rows {
                let result = DatabaseSearchResult(
                    heading: row[1] as? String ?? "",
                    subheading: row[2] as? String ?? "",
                    content: "\(row[3] as? String ?? "")\n\(row[4] as? String ?? "")",
                    explanation: row[8] as? String ?? "",
                    kuralId: Int(row[0] as? Int64 ?? 0)
                )
                results.append(result)
            }
        } catch {
            print("Error searching Tamil content: \(error.localizedDescription)")
        }

        return results
    }
}
