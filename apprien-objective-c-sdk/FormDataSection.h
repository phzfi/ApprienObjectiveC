
#import <string>

class FormDataSection
{
public:
    /// <summary>
    /// The section's name.
    /// </summary>
    std::string Name;
    /// <summary>
    /// Binary data contained in this section.
    /// </summary>
    const char *Data;
    FormDataSection()
    {
        Name = "";
        Data = "";
    }
    FormDataSection(std::string name, const char *data)
    {
        Name = name;
        Data = data;
    }
};
