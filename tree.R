# Load necessary libraries
library(caret)       # For data splitting and evaluation
library(rpart)       # For decision tree modeling
library(rpart.plot)  # For visualizing the tree
library(ggplot2)     # For visualization
library(dplyr) 


# For data manipulation
# Download the data from the GitHub repository
url <- "https://github.com/alemxral/cv/raw/master/bank.csv"
data <- read.csv(url, sep = ";")

# Convert character columns to factors
convert_to_factors <- function(df) {
  data.frame(lapply(df, function(x) {
    if (is.character(x)) {
      factor(x)
    } else {
      x
    }
  }))
}
data <- convert_to_factors(data)

# Check the current distribution of the loan variable
table(data$loan)

# Set a seed for reproducibility
set.seed(123)

# Modify the loan variable to assign random "yes" or "no" values
data <- data %>%
  mutate(loan = sample(c("yes", "no"), size = n(), replace = TRUE))

# Check the new distribution to confirm balance
table(data$loan)

# Ensure the dependent variable is binary and properly factored
data$loan <- factor(data$loan, levels = c("no", "yes"))

# Split the data into training and testing sets
set.seed(123)
train_index <- createDataPartition(data$loan, p = 0.5, list = FALSE)
train_data <- data[train_index, ]
test_data <- data[-train_index, ]

# Train the decision tree model with less restrictive split criteria
model <- rpart(loan ~ duration + job, data = train_data, method = "class", control = rpart.control(cp = 0.005))

# Visualize the decision tree
rpart.plot(model, type = 3, extra = 1)

# Plot the original data points
plot1 <- ggplot(train_data, aes(x = duration, y = as.numeric(job), color = loan)) +
  geom_point(size = 3) +
  labs(title = "Data Points", x = "Duration", y = "Job (numeric representation)") +
  theme_minimal()

print(plot1)

# Generate a grid of points for decision boundary
grid <- expand.grid(
  duration = seq(min(train_data$duration), max(train_data$duration), length.out = 100),
  job = levels(train_data$job)
)

# Predict classifications for the grid
grid$loan <- predict(model, newdata = grid, type = "class")

# Plot the decision boundary
plot2 <- ggplot() +
  geom_tile(data = grid, aes(x = duration, y = as.numeric(job), fill = loan), alpha = 0.3) +
  geom_point(data = train_data, aes(x = duration, y = as.numeric(job), color = loan), size = 3) +
  labs(title = "Decision Boundary", x = "Duration", y = "Job (numeric representation)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))  # Centering the title

print(plot2)

# Evaluate the model on the test set
predictions <- predict(model, newdata = test_data, type = "class")
conf_matrix <- confusionMatrix(predictions, test_data$loan)
print(conf_matrix)
