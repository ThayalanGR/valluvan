import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ContentViewModel(application: Application) : AndroidViewModel(application) {
    private val dbManager = DatabaseManager.getInstance(application)

    private val _selectedPal = MutableLiveData<String>("Virtue")
    val selectedPal: LiveData<String> = _selectedPal

    private val _selectedLanguage = MutableLiveData<String>("English")
    val selectedLanguage: LiveData<String> = _selectedLanguage

    private val _iyals = MutableLiveData<List<String>>()
    val iyals: LiveData<List<String>> = _iyals

    private val _adhigarams = MutableLiveData<List<String>>()
    val adhigarams: LiveData<List<String>> = _adhigarams

    private val _kurals = MutableLiveData<List<List<String>>>()
    val kurals: LiveData<List<List<String>>> = _kurals

    private val _searchResults = MutableLiveData<List<SearchResult>>()
    val searchResults: LiveData<List<SearchResult>> = _searchResults

    private val _explanation = MutableLiveData<SpannableString>()
    val explanation: LiveData<SpannableString> = _explanation

    fun setSelectedPal(pal: String) {
        _selectedPal.value = pal
        loadIyals()
    }

    fun setSelectedLanguage(language: String) {
        _selectedLanguage.value = language
        loadIyals()
    }

    fun loadIyals() {
        viewModelScope.launch {
            val loadedIyals = withContext(Dispatchers.IO) {
                dbManager.getIyals(_selectedPal.value!!, _selectedLanguage.value!!)
            }
            _iyals.value = loadedIyals
        }
    }

    fun loadAdhigarams(iyal: String) {
        viewModelScope.launch {
            val loadedAdhigarams = withContext(Dispatchers.IO) {
                dbManager.getAdhigarams(iyal, _selectedLanguage.value!!)
            }
            _adhigarams.value = loadedAdhigarams
        }
    }

    fun loadKurals(adhigaram: String) {
        viewModelScope.launch {
            val loadedKurals = withContext(Dispatchers.IO) {
                if (_selectedLanguage.value in listOf("Tamil", "Telugu", "Hindi")) {
                    dbManager.getFirstLine(adhigaram, _selectedLanguage.value!!)
                } else {
                    dbManager.getSingleLine(adhigaram, _selectedLanguage.value!!).map { listOf(it) }
                }
            }
            _kurals.value = loadedKurals
        }
    }

    fun searchContent(query: String) {
        viewModelScope.launch {
            val results = withContext(Dispatchers.IO) {
                dbManager.searchContent(query)
            }
            _searchResults.value = results
        }
    }

    fun loadExplanation(kuralId: Int) {
        viewModelScope.launch {
            val loadedExplanation = withContext(Dispatchers.IO) {
                dbManager.getExplanation(kuralId, _selectedLanguage.value!!)
            }
            _explanation.value = loadedExplanation
        }
    }
}