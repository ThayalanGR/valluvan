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

    
    public func getIyals(for pal: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்")
        let palExpr = Expression<String>("பால்")
        let iyalExpr = Expression<String>("இயல்")
        
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
 
    public func getAdhigarams(for iyal: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்")
        let iyalExpr = Expression<String>("இயல்")
        let adhigaramExpr = Expression<String>("அதிகாரம்")
        
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
    
    public func getFirstLine(for adhigaram: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = Expression<Int>("திருக்குறள்") 
        let adhigaramExpr = Expression<String>("அதிகாரம்")
        let firstLineExpr = Expression<String>("First Line")
        let secondLineExpr = Expression<String>("Second Line")
        
        var kurals: [String] = []
        do {
            let query = tirukkuralTable
                .select(firstLineExpr, secondLineExpr)   
                .filter(adhigaramExpr == adhigaram)
                .order(kuralId)  

            for row in try db!.prepare(query) {
                kurals.append(row[firstLineExpr])
                kurals.append(row[secondLineExpr])
            }
        } catch {
            print("Error fetching first line: \(error)")
        }
        return kurals
    }
    
    func getExplanation(for adhigaram: String, lines: [String]) -> String {
        // Implement the logic to fetch the explanation from your database
        // For now, we'll return a placeholder
        return "This is the explanation for \(adhigaram): \(lines.joined(separator: " "))"
    }
}
