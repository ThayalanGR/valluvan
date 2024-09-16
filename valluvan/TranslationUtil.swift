import Foundation

class TranslationUtil {
    static func getTranslation(for word: String, to targetLanguage: String) async throws -> String {
      
        let translations: [String: [String: String]] = [
            "English": [
                "Miscelleanous": "Misc"
            ],
            "telugu": [
                "Preface": "ముందుమాట",
                "Domestic Virtue": "గృహస్థ ధర్మం",
                "Ascetic Virtue": "సన్యాస ధర్మం",
                "Royalty": "రాజరికం",
                "Ministry": "మంత్రిత్వశాఖ",
                "Politics": "రాజకీయాలు",
                "Friendship": "స్నేహం",
                "Miscelleanous": "వివిధ విషయాలు",
                "Pre-marital love": "వివాహపూర్వ ప్రేమ",
                "Post-marital love": "వివాహానంతర ప్రేమ"
            ],
            "hindi": [
                "Preface": "प्रस्तावना",
                "Domestic Virtue": "गृहस्थ धर्म",
                "Ascetic Virtue": "संन्यास धर्म",
                "Royalty": "राजत्व",
                "Ministry": "मंत्रालय",
                "Politics": "राजनीति",
                "Friendship": "मित्रता",
                "Miscelleanous": "विविध",
                "Pre-marital love": "विवाह पूर्व प्रेम",
                "Post-marital love": "विवाह के बाद का प्रेम"
            ],
            "kannad": [
                "Preface": "ಮುನ್ನುಡಿ",
                "Domestic Virtue": "ಗೃಹಸ್ಥ ಧರ್ಮ",
                "Ascetic Virtue": "ಸನ್ಯಾಸ ಧರ್ಮ",
                "Royalty": "ರಾಜತ್ವ",
                "Ministry": "ಸಚಿವಾಲಯ",
                "Politics": "ರಾಜಕೀಯ",
                "Friendship": "ಸ್ನೇಹ",
                "Miscelleanous": "ವಿವಿಧ",
                "Pre-marital love": "ವಿವಾಹಪೂರ್ವ ಪ್ರೀತಿ",
                "Post-marital love": "ವಿವಾಹಾನಂತರ ಪ್ರೀತಿ"
            ],
            "french": [
                "Preface": "Préface",
                "Domestic Virtue": "Vertu domestique",
                "Ascetic Virtue": "Vertu ascétique",
                "Royalty": "Royauté",
                "Ministry": "Ministère",
                "Politics": "Politique",
                "Friendship": "Amitié",
                "Miscelleanous": "Divers",
                "Pre-marital love": "Amour prénuptial",
                "Post-marital love": "Amour post-marital"
            ],
            "arabic": [
                "Preface": "مقدمة",
                "Domestic Virtue": "الفضيلة المنزلية",
                "Ascetic Virtue": "الفضيلة الزهدية",
                "Royalty": "الملكية",
                "Ministry": "الوزارة",
                "Politics": "السياسة",
                "Friendship": "الصداقة",
                "Miscelleanous": "متنوع",
                "Pre-marital love": "الحب قبل الزواج",
                "Post-marital love": "الحب بعد الزواج"
            ],
            "chinese": [
                "Preface": "序言",
                "Domestic Virtue": "家庭美德",
                "Ascetic Virtue": "苦行美德",
                "Royalty": "王权",
                "Ministry": "部门",
                "Politics": "政治",
                "Friendship": "友谊",
                "Miscelleanous": "杂项",
                "Pre-marital love": "婚前恋爱",
                "Post-marital love": "婚后恋爱"
            ],
            "german": [
                "Preface": "Vorwort",
                "Domestic Virtue": "Häusliche Tugend",
                "Ascetic Virtue": "Asketische Tugend",
                "Royalty": "Königtum",
                "Ministry": "Ministerium",
                "Politics": "Politik",
                "Friendship": "Freundschaft",
                "Miscelleanous": "Verschiedenes",
                "Pre-marital love": "Voreheliche Liebe",
                "Post-marital love": "Nacheheliche Liebe"
            ],
            "korean": [
                "Preface": "서문",
                "Domestic Virtue": "가정의 미덕",
                "Ascetic Virtue": "금욕의 미덕",
                "Royalty": "왕권",
                "Ministry": "부처",
                "Politics": "정치",
                "Friendship": "우정",
                "Miscelleanous": "기타",
                "Pre-marital love": "혼전 사랑",
                "Post-marital love": "혼후 사랑"
            ],
            "malay": [
                "Preface": "Prakata",
                "Domestic Virtue": "Kebajikan Domestik",
                "Ascetic Virtue": "Kebajikan Pertapaan",
                "Royalty": "Kerajaan",
                "Ministry": "Kementerian",
                "Politics": "Politik",
                "Friendship": "Persahabatan",
                "Miscelleanous": "Pelbagai",
                "Pre-marital love": "Cinta Pra Perkahwinan",
                "Post-marital love": "Cinta Pasca Perkahwinan"
            ],
            "malayalam": [
                "Preface": "ആമുഖം",
                "Domestic Virtue": "കുടുംബ സദ്ഗുണം",
                "Ascetic Virtue": "സന്യാസ സദ്ഗുണം",
                "Royalty": "രാജത്വം",
                "Ministry": "മന്ത്രാലയം",
                "Politics": "രാഷ്ട്രീയം",
                "Friendship": "സൗഹൃദം",
                "Miscelleanous": "പലവക",
                "Pre-marital love": "വിവാഹപൂർവ്വ പ്രണയം",
                "Post-marital love": "വിവാഹാനന്തര പ്രണയം"
            ],
            "polish": [
                "Preface": "Przedmowa",
                "Domestic Virtue": "Cnota domowa",
                "Ascetic Virtue": "Cnota ascetyczna",
                "Royalty": "Królewskość",
                "Ministry": "Ministerstwo",
                "Politics": "Polityka",
                "Friendship": "Przyjaźń",
                "Miscelleanous": "Różne",
                "Pre-marital love": "Miłość przedmałżeńska",
                "Post-marital love": "Miłość pomałżeńska"
            ],
            "russian": [
                "Preface": "Предисловие",
                "Domestic Virtue": "Домашняя добродетель",
                "Ascetic Virtue": "Аскетическая добродетель",
                "Royalty": "Королевская власть",
                "Ministry": "Министерство",
                "Politics": "Политика",
                "Friendship": "Дружба",
                "Miscelleanous": "Разное",
                "Pre-marital love": "Добрачная любовь",
                "Post-marital love": "Послебрачная любовь"
            ],
            "singalam": [
                "Preface": "පෙරවදන",
                "Domestic Virtue": "ගෘහස්ථ ගුණය",
                "Ascetic Virtue": "තපස් ගුණය",
                "Royalty": "රාජත්වය",
                "Ministry": "අමාත්යාංශය",
                "Politics": "දේශපාලනය",
                "Friendship": "මිත්රත්වය",
                "Miscelleanous": "විවිධ",
                "Pre-marital love": "විවාහයට පෙර ආදරය",
                "Post-marital love": "විවාහයෙන් පසු ආදරය"
            ],
            "swedish": [
                "Preface": "Förord",
                "Domestic Virtue": "Huslig dygd",
                "Ascetic Virtue": "Asketisk dygd",
                "Royalty": "Kunglig värdighet",
                "Ministry": "Ministerium",
                "Politics": "Politik",
                "Friendship": "Vänskap",
                "Miscelleanous": "Diverse",
                "Pre-marital love": "Kärlek före äktenskapet",
                "Post-marital love": "Kärlek efter äktenskapet"
            ]
        ]
        
        return translations[targetLanguage]?[word] ?? word
    }
}
