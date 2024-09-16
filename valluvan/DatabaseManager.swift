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
        let kuralId = Expression<Int>("kno")
        let palExpr = language == "Tamil" ? Expression<String>("pal") : Expression<String>("title")
        let iyalExpr = language == "Tamil" ? Expression<String>("iyal") : Expression<String>("heading")
        
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
 
    public func getAdhigarams(for iyal: String, language: String) -> ([String], [Int], [String], [String]) {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("kno")
        let iyalExpr = language == "Tamil" ? Expression<String>("iyal") : Expression<String>("heading")
        let adhigaramExpr = language == "Tamil" ? Expression<String>("tchapter") : Expression<String>("chapter")
        let adhigaramSongExpr = Expression<String>("tchapter") 
        var adhigarams: [String] = []
        var kuralIds: [Int] = []
        var adhigaramSongs: [String] = []
        var originalAdhigarams: [String] = []
        do {
            let query = tirukkuralTable
                .select(adhigaramExpr, kuralId, adhigaramSongExpr)
                .filter(iyalExpr == iyal)
                .group(adhigaramExpr)
                .order(kuralId)
            
            for row in try db!.prepare(query) {
                adhigarams.append(row[adhigaramExpr])   
                originalAdhigarams.append(row[adhigaramExpr])
                kuralIds.append(row[kuralId])
                adhigaramSongs.append(row[adhigaramSongExpr])
            }
        } catch {
            print("Error fetching adhigarams: \(error)")
        }

        return (adhigarams, kuralIds, adhigaramSongs, originalAdhigarams)
    } 

    public func getSingleLine(for adhigaram: String, language: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("kno") 
        let adhigaramExpr = Expression<String>("chapter")
        
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
        let kuralId = Expression<Int>("kno") 
        let adhigaramExpr = language == "Tamil" ? Expression<String>("tchapter") : Expression<String>("chapter")
        
        let firstLineExpr: Expression<String>
        let secondLineExpr: Expression<String>
        
        switch language {
        case "Tamil":
            firstLineExpr = Expression<String>("firstline")
            secondLineExpr = Expression<String>("secondline")
        case "telugu":
            firstLineExpr = Expression<String>("telugu1")
            secondLineExpr = Expression<String>("telugu2")
        case "hindi":
            firstLineExpr = Expression<String>("hindi1")
            secondLineExpr = Expression<String>("hindi2")
        default:
            firstLineExpr = Expression<String>("efirstline")
            secondLineExpr = Expression<String>("esecondline")
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
        let kuralIdExpr = Expression<Int>("kno")
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
            explanationExpr = Expression<String>("kalaignar")
            manaExplanationExpr = Expression<String>("manakudavar")
            pariExplanationExpr = Expression<String>("parimelazhagar")
            varaExplanationExpr = Expression<String>("varadarajanar")
            popsExplanationExpr = Expression<String>("salomon")
            muniExplanationExpr = Expression<String>("munisamy")
            query = tirukkuralTable
                .select(explanationExpr, manaExplanationExpr, pariExplanationExpr, varaExplanationExpr, popsExplanationExpr, muniExplanationExpr)
                .filter(kuralIdExpr == kuralId) 
            do {                
                if let row = try db!.pluck(query) {
                    let boldAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
                    
                    appendExplanation(to: &attributedExplanation, title: "கலைஞர் விளக்கம்: ", content: row[explanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "மணக்குடவர் விளக்கம்: ", content: row[manaExplanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "பரிமேலழகர் விளக்கம்: ", content: row[pariExplanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "மு. வரதராசன் விளக்கம்: ", content: row[varaExplanationExpr], boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "சாலமன் பாப்பையா விளக்கம்: ", content: row[popsExplanationExpr], boldAttributes: boldAttributes)    
                    appendExplanation(to: &attributedExplanation, title: "வீ. முனிசாமி விளக்கம்: ", content: row[muniExplanationExpr], boldAttributes: boldAttributes, isLast: true)
                }
            } catch {
                print("Error fetching Tamil explanation: \(error)")
            }   
        default:
            explanationExpr = Expression<String>("explanation") 
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

        if language != "English" && language != "telugu" && language != "hindi" {
            searchQuery = """
                SELECT "kno", "heading", "chapter", "efirstline", "esecondline", "explanation", "\(language)"
                FROM tirukkural
                WHERE "heading" LIKE ? OR "chapter" LIKE ? OR "efirstline" LIKE ? OR "esecondline" LIKE ? OR "explanation" LIKE ? OR "\(language)" LIKE ?
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
                    SELECT "kno", "heading", "chapter", "efirstline", "esecondline", "explanation"
                    FROM tirukkural
                    WHERE "heading" LIKE ? OR "chapter" LIKE ? OR "efirstline" LIKE ? OR "esecondline" LIKE ? OR "explanation" LIKE ?
                    LIMIT 20
                """
            } else {
                searchQuery = """
                    SELECT "kno", "heading", "chapter", "\(language)1", "\(language)2", "explanation"
                    FROM tirukkural
                    WHERE "heading" LIKE ? OR "chapter" LIKE ? OR "\(language)1" LIKE ? OR "\(language)2" LIKE ? OR "explanation" LIKE ?
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
            SELECT "kno", "iyal", "tchapter", "firstline", "secondline", "manakudavar", "parimelazhagar", "varadarajanar", "kalaignar", "salomon", "munisamy", "efirstline", "esecondline", "explanation"
            FROM tirukkural
            WHERE "iyal" LIKE ? OR "tchapter" LIKE ? OR "firstline" LIKE ? OR "secondline" LIKE ? OR "manakudavar" LIKE ? OR "parimelazhagar" LIKE ? OR "varadarajanar" LIKE ? OR "kalaignar" LIKE ? OR "salomon" LIKE ? OR "munisamy" LIKE ? OR "efirstline" LIKE ? OR "esecondline" LIKE ? OR "explanation" LIKE ?
            LIMIT 20
        """
        let searchPattern = "%\(query)%"

        do {
            let rows = try db!.prepare(searchQuery, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern)
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

    func getKuralById(_ kuralId: Int, language: String) -> DatabaseSearchResult? {
        let tirukkuralTable = Table("tirukkural")
        let kuralIdExpr = Expression<Int>("kno")
        let headingExpr = Expression<String>("heading")
        let subheadingExpr = Expression<String>("chapter")
        let contentExpr1 = Expression<String>("firstline")
        let contentExpr2 = Expression<String>("secondline")
        let tfirstLineExpr = Expression<String>("telugu1")
        let tsecondLineExpr = Expression<String>("telugu2")
        let hfirstLineExpr = Expression<String>("hindi1")
        let hsecondLineExpr = Expression<String>("hindi2")
        let explanationExpr: Expression<String>
        
        switch language {
        case "Tamil":
            explanationExpr = Expression<String>("kalaignar")
        case "English", "hindi", "telugu":
            explanationExpr = Expression<String>("explanation")
        default:
            explanationExpr = Expression<String>(language)
        }

        do {
            let query = tirukkuralTable
                .select(headingExpr, subheadingExpr, contentExpr1, contentExpr2, tfirstLineExpr, tsecondLineExpr, hfirstLineExpr, hsecondLineExpr, explanationExpr)
                .filter(kuralIdExpr == kuralId)

            if let row = try db!.pluck(query) {
                return DatabaseSearchResult(
                    heading: row[headingExpr],
                    subheading: row[subheadingExpr],
                    content: language == "telugu" ? "\(row[tfirstLineExpr])\n\(row[tsecondLineExpr])" : language == "hindi" ? "\(row[hfirstLineExpr])\n\(row[hsecondLineExpr])" : "\(row[contentExpr1])\n\(row[contentExpr2])",
                    explanation: row[explanationExpr],
                    kuralId: kuralId
                )
            }
        } catch {
            print("Error fetching Kural by ID: \(error)")
        }

        return nil
    }
}
