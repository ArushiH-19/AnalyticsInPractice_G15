# Load necessary libraries
library(dplyr)
library(readr)
library(stringr)

# Read dataset
root_df <- read_csv("/Users/irismo/Desktop/Root_Tab2_Transformed.csv")

# pre-processing
# Convert DATE format to DD-MM-YYYY
root_df <- root_df %>%
  mutate(DATE = format(as.Date(DATE, format = "%m/%d/%Y"), "%d-%m-%Y"))

# Remove rows with any missing values (NA, empty strings, spaces)
root_df <- root_df %>%
  filter(complete.cases(.)) %>%
  filter_all(all_vars(. != ""))  # Ensure no empty strings

# Standardize column names: replace spaces with underscores
colnames(root_df) <- colnames(root_df) %>%
  str_replace_all(" ", "_") %>%  # Replace spaces
  str_replace_all("\\.", "_") %>% # Replace dots
  tolower()  # Convert to lowercase for consistency

# Save cleaned dataset to a new CSV file
write_csv(root_df, "/Users/irismo/Desktop/Root_tab2_clean.csv")

# Print confirmation message
print("Data cleaning complete. File saved as Root_tab2_clean.csv")

------EDA---------
  ---identify the most negatively impacted lots------
  
  # Load necessary libraries
  library(dplyr)
library(readr)
library(tidyr)  # Ensure pivot_wider() is available
library(ggplot2)
library(reshape2)
install.packages("ggcorrplot")
library(ggcorrplot)

# Read dataset
root_final <- read_csv("/Users/irismo/Desktop/Root_final.csv",
                       show_col_types = FALSE)

# Convert value to numeric (remove "%")
root_final <- root_final %>%
  mutate(value = as.numeric(gsub("%", "", value)))

# Step 1: Identify the worst LOTs based on lowest % Good Root
lot_ranking <- root_final %>%
  filter(indicator == "% Good Root") %>%  
  group_by(lot) %>%
  summarise(avg_good_root = mean(value, na.rm = TRUE),  # Take avg across 4 blocks
            .groups = "drop") %>%
  arrange(avg_good_root)  # Sort by lowest % Good Root

# Determine the top 10% worst LOTs
total_lots <- nrow(lot_ranking)
top_lot_count <- ceiling(total_lots * 0.10)
worst_lots <- lot_ranking %>%
  slice(1:top_lot_count)  # Select worst LOTs

# Step 2: Identify the worst BLOCK in each of the worst LOTs
worst_blocks <- root_final %>%
  filter(lot %in% worst_lots$lot & indicator == "% Good Root") %>%
  group_by(lot, block) %>%
  summarise(avg_good_root = mean(value, na.rm = TRUE), .groups = "drop") %>%
  arrange(lot, avg_good_root) %>%  # Sort by lowest % Good Root per LOT
  group_by(lot) %>%
  slice(1)  # Pick the worst BLOCK per LOT

# Display results
print(worst_lots)  # Worst LOTs based on avg % Good Root
print(worst_blocks)  # Worst BLOCK in each worst LOT

-----------------visualize------------
  # Step 1: Rank LOTs by Root Condition and visualize
  lot_root_summary <- root_final %>%
  filter(indicator == "% Good Root") %>%
  group_by(lot) %>%
  summarise(avg_good_root = mean(value, na.rm = TRUE), .groups = "drop") %>%
  arrange(avg_good_root)

# Visualization: Line chart showing LOT ranking by Root Condition
ggplot(lot_root_summary, aes(x = reorder(lot, avg_good_root), 
                             y = avg_good_root, group = 1)) +
  geom_line(color = "blue") +                      # Line connecting points
  geom_point(size = 2, color = "red") +            # Add points
  geom_text(aes(label = round(avg_good_root, 1)),  # Add text labels
            vjust = -0.5, size = 3.5) +            # Adjust label position
  theme_minimal() +
  labs(title = "LOTs Ranked by % Good Root", 
       x = "LOT (Worst to Best)", 
       y = "% Good Root") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x labels


# Step 2: Find most frequent infestation types
infestation_counts <- root_final %>%
  filter(indicator %in% c("% Scale Insects", "% Snails", "% Symphylans",
                          "% Ants", "% L. Red Head", "% Weevil")) %>%
  filter(value > 0) %>%
  count(indicator, sort = TRUE)

# Visualization: Horizontal bar chart with gradient color
ggplot(infestation_counts, aes(x = reorder(indicator, n), y = n, fill = n)) +
  geom_col() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +  # Gradient color
  coord_flip() +  # Horizontal bar chart
  geom_text(aes(label = n), hjust = -0.2, size = 3.5) +  # Add labels
  theme_minimal() +
  labs(title = "Infestation Frequency Across All LOTs", 
       x = "Infestation Type", 
       y = "Frequency") +
  theme(legend.position = "none")  # Remove unnecessary legend

-----pie chart approach for step 2-------
  # Load necessary libraries
  library(ggrepel)  # For placing labels outside the pie

# Step 2: Compute infestation frequency and percentage
infestation_counts <- root_final %>%
  filter(indicator %in% c("% Scale Insects", "% Snails", "% Symphylans",
                          "% Ants", "% L. Red Head", "% Weevil")) %>%
  filter(value > 0) %>%
  count(indicator, sort = TRUE) %>%
  mutate(percentage = round(n / sum(n) * 100, 1))  # Compute percentage

# Define a custom color palette (darker colors for higher frequency)
custom_colors <- c("#08306b", "#08519c", "#2171b5", "#4292c6", "#6baed6", "#9ecae1")

# Visualization: Pie chart with percentage labels
ggplot(infestation_counts, aes(x = "", y = percentage, fill = reorder(indicator, -percentage))) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar(theta = "y") +  # Convert to pie chart
  scale_fill_manual(values = custom_colors) +  # Apply custom color palette
  geom_text(aes(label = paste0(indicator, "\n", percentage, "%")), 
            position = position_stack(vjust = 0.5), 
            size = 4, color = "white") +  # Ensure labels are readable
  theme_void() +
  labs(title = "Infestation Frequency Distribution")


-----correlation analysis-----
  # Step 1: Compute average % Good Root per LOT
  lot_root_summary <- root_final %>%
  filter(indicator == "% Good Root") %>%
  group_by(lot) %>%
  summarise(avg_good_root = mean(value, na.rm = TRUE), 
            .groups = "drop")

# Step 2: Prepare dataset for correlation analysis
cor_data <- root_final %>%
  filter(indicator %in% c("% Symphylans", "% Ants", 
                          "% L. Red Head")) %>%
  pivot_wider(names_from = indicator, values_from = value, 
              values_fill = 0) %>%
  left_join(lot_root_summary, by = "lot")  # Merge with avg % Good Root

# Remove unnecessary columns (ensure block is NOT present)
cor_data <- cor_data %>%
  select(-contains("block"))  

# Step 3: Compute correlation matrix
cor_matrix <- cor(cor_data[, -1], use = "pairwise.complete.obs")

# Step 4: Visualization - Heatmap of correlation (optimized)
ggcorrplot(cor_matrix, method = "circle", 
           title = "Correlation: Root Condition & Key Infestations")


-----pest average comparison-----
  # Compute the average infestation level for all 5 pests
  infestation_avg <- root_final %>%
  filter(indicator %in% c("% Snails", "% Symphylans", 
                          "% Ants", "% L. Red Head", "% Weevil")) %>%
  group_by(indicator) %>%
  summarise(mean_value = mean(value, na.rm = TRUE), 
            .groups = "drop") %>%
  arrange(desc(mean_value))  # Sort from highest to lowest

# Visualization: Horizontal bar chart with gradient color
ggplot(infestation_avg, aes(x = reorder(indicator, mean_value), 
                            y = mean_value, fill = mean_value)) +
  geom_col() +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +  # Gradient color
  coord_flip() +  # Horizontal bar chart
  geom_text(aes(label = paste0(round(mean_value, 1), "%")), 
            hjust = -0.2, size = 4) +  # Add text labels for values
  theme_minimal() +
  labs(title = "Average Infestation Level Across All LOTs", 
       x = "Infestation Type", 
       y = "Average Infestation Level (%)") +
  theme(legend.position = "none")  # Remove unnecessary legend

