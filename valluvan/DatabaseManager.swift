import Foundation
import SQLite // Make sure this import is correct

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
            
                print("Query iyals: \(query)")
            for row in try db!.prepare(query) {
                iyals.append(row[iyalExpr])
            }
        } catch {
            print("Error fetching iyals: \(error)")
        } 
            
        return iyals
    }
 
    public func getAdhigarams(for iyal: String, language: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்")
        let iyalExpr = language == "Tamil" ? Expression<String>("இயல்") : Expression<String>("English Heading")
        let adhigaramExpr = language == "Tamil" ? Expression<String>("அதிகாரம்") : Expression<String>("English Chapter")
        
        var adhigarams: [String] = []
        
        do {
            let query = tirukkuralTable
                .select(adhigaramExpr)
                .filter(iyalExpr == iyal)
                .group(adhigaramExpr)
                .order(kuralId)
            
            for row in try db!.prepare(query) {
                adhigarams.append(row[adhigaramExpr])
            }
        } catch {
            print("Error fetching adhigarams: \(error)")
        }
        
        return adhigarams
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
    
    func getExplanation(for kuralId: Int, language: String) -> String {
        let tirukkuralTable = Table("tirukkural")
        let kuralIdExpr = Expression<Int>("திருக்குறள்")
        let explanationExpr: Expression<String>
        
        switch language {
        case "Tamil":
            explanationExpr = Expression<String>("கலைஞர்") 
        default:
            explanationExpr = Expression<String>("Explanation") 
        }
        var explanation: String?
        do {
            let query = tirukkuralTable
                .select(explanationExpr)
                .filter(kuralIdExpr == kuralId)   
            
            if let row = try db!.pluck(query) {
                explanation = row[explanationExpr]
            }
        } catch {
            print("Error fetching explanation: \(error)")
        } 
        return explanation ?? "No explanation found"
    }
}
