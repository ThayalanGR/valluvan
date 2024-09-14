import Foundation

class TranslationUtil {
    static func getTranslation(for word: String, to targetLanguage: String) async throws -> String {
      
        let translations: [String: [String: String]] = [
            "Tamil": [
                "Preface": "பாயிரவியல்",
                "Domestic Virtue": "இல்லறவியல்",
                "Ascetic Virtue": "துறவறவியல்",
                "Royalty": "அரசியல்",
                "Ministry": "அமைச்சியல்",
                "Politics": "அரணியல்",
                "Friendship": "நட்பியல்",
                "Miscellaneous": "பலவியல்",
                "Pre marital love": "களவியல்",
                "Post marital love": "கற்பியல்"
            ],
            "English": [
                "Preface": "Preface",
                "Domestic Virtue": "Domestic Virtue",
                "Ascetic Virtue": "Ascetic Virtue",
                "Royalty": "Royalty",
                "Ministry": "Ministry",
                "Politics": "Politics",
                "Friendship": "Friendship",
                "Miscellaneous": "Miscellaneous",
                "Pre marital love": "Pre marital love",
                "Post marital love": "Post marital love"
            ],
            "Telugu": [
                "Preface": "ముందుమాట",
                "Domestic Virtue": "గృహస్థ ధర్మం",
                "Ascetic Virtue": "సన్యాస ధర్మం",
                "Royalty": "రాజరికం",
                "Ministry": "మంత్రిత్వశాఖ",
                "Politics": "రాజకీయాలు",
                "Friendship": "స్నేహం",
                "Miscellaneous": "వివిధ విషయాలు",
                "Pre marital love": "వివాహపూర్వ ప్రేమ",
                "Post marital love": "వివాహానంతర ప్రేమ"
            ],
            "Hindi": [
                "Preface": "प्रस्तावना",
                "Domestic Virtue": "गृहस्थ धर्म",
                "Ascetic Virtue": "संन्यास धर्म",
                "Royalty": "राजत्व",
                "Ministry": "मंत्रालय",
                "Politics": "राजनीति",
                "Friendship": "मित्रता",
                "Miscellaneous": "विविध",
                "Pre marital love": "विवाह पूर्व प्रेम",
                "Post marital love": "विवाह के बाद का प्रेम"
            ],
            "Kannad": [
                "Preface": "ಮುನ್ನುಡಿ",
                "Domestic Virtue": "ಗೃಹಸ್ಥ ಧರ್ಮ",
                "Ascetic Virtue": "ಸನ್ಯಾಸ ಧರ್ಮ",
                "Royalty": "ರಾಜತ್ವ",
                "Ministry": "ಸಚಿವಾಲಯ",
                "Politics": "ರಾಜಕೀಯ",
                "Friendship": "ಸ್ನೇಹ",
                "Miscellaneous": "ವಿವಿಧ",
                "Pre marital love": "ವಿವಾಹಪೂರ್ವ ಪ್ರೀತಿ",
                "Post marital love": "ವಿವಾಹಾನಂತರ ಪ್ರೀತಿ"
            ],
            "French": [
                "Preface": "Préface",
                "Domestic Virtue": "Vertu domestique",
                "Ascetic Virtue": "Vertu ascétique",
                "Royalty": "Royauté",
                "Ministry": "Ministère",
                "Politics": "Politique",
                "Friendship": "Amitié",
                "Miscellaneous": "Divers",
                "Pre marital love": "Amour prénuptial",
                "Post marital love": "Amour post-marital"
            ],
            "Arabic": [
                "Preface": "مقدمة",
                "Domestic Virtue": "الفضيلة المنزلية",
                "Ascetic Virtue": "الفضيلة الزهدية",
                "Royalty": "الملكية",
                "Ministry": "الوزارة",
                "Politics": "السياسة",
                "Friendship": "الصداقة",
                "Miscellaneous": "متنوع",
                "Pre marital love": "الحب قبل الزواج",
                "Post marital love": "الحب بعد الزواج"
            ],
            "Chinese": [
                "Preface": "序言",
                "Domestic Virtue": "家庭美德",
                "Ascetic Virtue": "苦行美德",
                "Royalty": "王权",
                "Ministry": "部门",
                "Politics": "政治",
                "Friendship": "友谊",
                "Miscellaneous": "杂项",
                "Pre marital love": "婚前恋爱",
                "Post marital love": "婚后恋爱"
            ],
            "German": [
                "Preface": "Vorwort",
                "Domestic Virtue": "Häusliche Tugend",
                "Ascetic Virtue": "Asketische Tugend",
                "Royalty": "Königtum",
                "Ministry": "Ministerium",
                "Politics": "Politik",
                "Friendship": "Freundschaft",
                "Miscellaneous": "Verschiedenes",
                "Pre marital love": "Voreheliche Liebe",
                "Post marital love": "Nacheheliche Liebe"
            ],
            "Korean": [
                "Preface": "서문",
                "Domestic Virtue": "가정의 미덕",
                "Ascetic Virtue": "금욕의 미덕",
                "Royalty": "왕권",
                "Ministry": "부처",
                "Politics": "정치",
                "Friendship": "우정",
                "Miscellaneous": "기타",
                "Pre marital love": "혼전 사랑",
                "Post marital love": "혼후 사랑"
            ],
            "Malay": [
                "Preface": "Prakata",
                "Domestic Virtue": "Kebajikan Domestik",
                "Ascetic Virtue": "Kebajikan Pertapaan",
                "Royalty": "Kerajaan",
                "Ministry": "Kementerian",
                "Politics": "Politik",
                "Friendship": "Persahabatan",
                "Miscellaneous": "Pelbagai",
                "Pre marital love": "Cinta Pra Perkahwinan",
                "Post marital love": "Cinta Pasca Perkahwinan"
            ],
            "Malayalam": [
                "Preface": "ആമുഖം",
                "Domestic Virtue": "കുടുംബ സദ്ഗുണം",
                "Ascetic Virtue": "സന്യാസ സദ്ഗുണം",
                "Royalty": "രാജത്വം",
                "Ministry": "മന്ത്രാലയം",
                "Politics": "രാഷ്ട്രീയം",
                "Friendship": "സൗഹൃദം",
                "Miscellaneous": "പലവക",
                "Pre marital love": "വിവാഹപൂർവ്വ പ്രണയം",
                "Post marital love": "വിവാഹാനന്തര പ്രണയം"
            ],
            "Polish": [
                "Preface": "Przedmowa",
                "Domestic Virtue": "Cnota domowa",
                "Ascetic Virtue": "Cnota ascetyczna",
                "Royalty": "Królewskość",
                "Ministry": "Ministerstwo",
                "Politics": "Polityka",
                "Friendship": "Przyjaźń",
                "Miscellaneous": "Różne",
                "Pre marital love": "Miłość przedmałżeńska",
                "Post marital love": "Miłość pomałżeńska"
            ],
            "Russian": [
                "Preface": "Предисловие",
                "Domestic Virtue": "Домашняя добродетель",
                "Ascetic Virtue": "Аскетическая добродетель",
                "Royalty": "Королевская власть",
                "Ministry": "Министерство",
                "Politics": "Политика",
                "Friendship": "Дружба",
                "Miscellaneous": "Разное",
                "Pre marital love": "Добрачная любовь",
                "Post marital love": "Послебрачная любовь"
            ],
            "Singalam": [
                "Preface": "පෙරවදන",
                "Domestic Virtue": "ගෘහස්ථ ගුණය",
                "Ascetic Virtue": "තපස් ගුණය",
                "Royalty": "රාජත්වය",
                "Ministry": "අමාත්යාංශය",
                "Politics": "දේශපාලනය",
                "Friendship": "මිත්රත්වය",
                "Miscellaneous": "විවිධ",
                "Pre marital love": "විවාහයට පෙර ආදරය",
                "Post marital love": "විවාහයෙන් පසු ආදරය"
            ],
            "Swedish": [
                "Preface": "Förord",
                "Domestic Virtue": "Huslig dygd",
                "Ascetic Virtue": "Asketisk dygd",
                "Royalty": "Kunglig värdighet",
                "Ministry": "Ministerium",
                "Politics": "Politik",
                "Friendship": "Vänskap",
                "Miscellaneous": "Diverse",
                "Pre marital love": "Kärlek före äktenskapet",
                "Post marital love": "Kärlek efter äktenskapet"
            ]
        ]
        
        return translations[targetLanguage]?[word] ?? word
    }
}