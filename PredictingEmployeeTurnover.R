# Predicting Employee Turnover Rate
# Data Analytics Case Study
# Dataset from Kaggle: 
# https://www.kaggle.com/datasets/jacksonchou/hr-data-for-analytics
# Analysis instructions from Field (2012).
# Code adapted from Field (2012).

# Install required packages if needed
# tidyverse for data import and wrangling
# ggplot2 (included in tidyverse) for visualizations
# corrplot for creating a correlation matrix visualization
#

# Step 1: Load Packages===============================================

library(tidyverse) # for wrangling data and visualizations
library(skimr)
library(ggplot2)

#Packages for logistic regression
library(car)
library(mlogit)
library(Rcmdr)


# Step 2: Import Data===============================================
# First, download the dataset from Kaggle:
# https://www.kaggle.com/datasets/jacksonchou/hr-data-for-analytics
# Set your working directory to where you have saved the csv file

# Importing and saving as a tibble dataframe named "df"
df <- as_tibble(read.csv("HR_comma_sep.csv",header=TRUE,
                         stringsAsFactors=TRUE))


# Step 3: Getting to know your data==================================

str(df) # Structure
glimpse(df) # Preview
colnames(df) # Lists the column names
skim_without_charts(df) # Part of the skimr package, detailed summary


# Step 4: Cleaning Your Data==================================

# Renaming "left" column as "left_employer for clarity
# Renaming "time_spend_company" as "tenure"
# Renaming "Work_accident" as "work_accident" for consistency
df <- df %>% 
  rename(left_employer = left) %>% 
  rename(tenure = time_spend_company) %>% 
  rename(work_accident = Work_accident) %>% 
  rename(average_monthly_hours = average_montly_hours)

# The column "sales" appears to be a list of employees' departments
# Let's rename it to "department"
df <- df %>% 
  rename(department = sales) 

# Releveling salary so that low, medium, and high are in the correct order
df$salary <- factor(df$salary, levels = c('low', 'medium', 'high'))

# Creating a separate dataframe so we can check for collinearity later on
num_df <- df

# Take a look at the cleaned data
skim_without_charts(df)

# Step 5: Exploring the Data Through Visualizations =================

#Percent Attrition Rate for the whole dataset
sum(df$left_employer)/nrow(df)*100

#Create aggregate dataframe to look at turnover rate by department
total_dept_df <- aggregate(df$left_employer, by=list(df$department), FUN=length)
left_dept_df <- aggregate(df$left_employer, by=list(df$department), FUN=sum)
total_dept_df$left <- left_dept_df$x 
total_dept_df$rate <- total_dept_df$left / total_dept_df$x
names(total_dept_df)[names(total_dept_df)=="x"] <- "total"
names(total_dept_df)[names(total_dept_df)=="Group.1"] <- "Department"
#total_dept_df now contains turnover rate by department

# Left Employer vs Satisfaction Rating
# Satisfaction level looks pretty normally distributed among leavers, but negatively skewed in 
# retained employees.
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=satisfaction_level, fill=left_employer)) +
  geom_histogram(position="dodge", bins=6)+ 
  labs(title="Distribution of Satisfaction Ratings",
  x="Satisfaction Rating", y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer vs Salary Level
# Low/Med/High Salary
# Looks like lower salary correlates with higher turnover
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(aes(x=salary, fill=left_employer)) +
  geom_bar(position="dodge")+
  labs(title="Distribution of Salaries", x="Salary Range", y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer vs Tenure 
# Very few people leave before 3 years of tenure. 
# Both distributions are positively skewed
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=tenure, fill=left_employer)) +
  geom_histogram(position="dodge", bins = 9) +
  labs(title="Distribution of Tenure",  x="Years with Company", y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer vs Score on Last Evaluation
# Bimodal distribution for leavers
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=last_evaluation, fill=left_employer)) +
  geom_histogram(position="dodge", bins = 15)+
  labs(title="Distribution of Evaluation Scores", x="Score on Last Evaluation", y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer vs work accident
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=work_accident, fill=left_employer)) +
  geom_histogram(position="dodge", bins = 2) +
  labs(title="Distribution of Work Accidents", x= "No Accident vs. Accident",y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer vs Promotions
# Very few employees have been promoted in the last 5 years. 
# Almost nobody who has been promoted has left the company.
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=promotion_last_5years, fill=left_employer)) +
  geom_histogram(position="dodge", bins=2)+
  labs(title = "Distribution of Promotions in the Last 5 Years", x="Not Promoted vs Promoted", 
        y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer vs number of projects
# A decent sized section of leavers had very few projects.
# The people with the very highest number of projects also left.
# Both distributions are positively skewed.
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=number_project, fill=left_employer)) +
  geom_histogram(position="dodge", bins = 5)+
  labs(title="Distribution of Project Count", x="Number of Projects", y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer vs. Monthly Hours Worked
# The distribution for leavers is bimodal, but the distribution of retained employees is closer to normal
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=average_monthly_hours, fill=left_employer)) +
  geom_histogram(position="dodge", bins = 20) +
  labs(title="Distribution of Hours Worked", x="Hours per Month", y="Employee Count") +
  scale_fill_discrete(name = "Group", labels = c("Retained", "Left"))

# Left Employer by department
# This chart doesn't tell us much. It would more useful to calculate rate by dept
df %>% 
  mutate(left_employer = as.factor(left_employer)) %>% 
  ggplot(mapping=aes(x=department, fill=left_employer)) +
  geom_bar(position="dodge")+
  labs(title="Distribution of Departments", x="Department", y="Employee Count") +
  scale_fill_discrete(name = "Group",  labels = c("Retained", "Left"))

# Show turnover rate by department
print(total_dept_df)


## Developing a Model for Prediction ==============================================

# Step 5: Create the function logisticPseudoR2s() ====================
# This function will calculate the Pseudo R2 values that are used instead of R2 in logistic regression

# To use it type logisticPseudoR2s(myLogisticModel)  
logisticPseudoR2s <- function(LogModel) {
  dev <- LogModel$deviance 
  nullDev <- LogModel$null.deviance 
  modelN <-  length(LogModel$fitted.values)
  R.l <-  1 -  dev / nullDev
  R.cs <- 1- exp ( -(nullDev - dev) / modelN)
  R.n <- R.cs / ( 1 - ( exp (-(nullDev / modelN))))
  cat("Pseudo R^2 for logistic regression\n")
  cat("Hosmer and Lemeshow R^2  ", round(R.l, 3), "\n")
  cat("Cox and Snell R^2        ", round(R.cs, 3), "\n")
  cat("Nagelkerke R^2           ", round(R.n, 3),    "\n")
}

# Step 6: Developing a Prediction Model ==============================

# Because we are predicting a binary variable using multiple factors, some of which are continuous, the 
# correct statistical test is logistic regression.

# Looking at first 6 cases of data
head(df)

# Looking at the dataframe structure
str(df)

# Convert to factors
df$left_employer <- as.factor(df$left_employer)
df$work_accident <- as.factor(df$work_accident)
df$promotion_last_5years <- as.factor(df$promotion_last_5years)


####Developing the Model================

##### Model 1: A model with everything----
turnoverModel.1 <- glm(left_employer ~ satisfaction_level + salary + tenure + last_evaluation + 
                        work_accident + average_monthly_hours + number_project + promotion_last_5years + 
                        department, data=df, family=binomial())
summary(turnoverModel.1)
  
# IT, marketing, product_mng, sales, support, and technical are all not significant at the alpha = .05 
# level and should be considered for removal from the model. 
# Consider creating binary factors for management and RandD (yes/no)


# Model 1 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.1$null.deviance - turnoverModel.1$deviance
# Degrees of freedom
chidf <- turnoverModel.1$df.null - turnoverModel.1$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.1)

# Cox and Snell's R squared can be interpreted to mean that turnoverModel.1 can account for 21% of 
# the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.1$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.1))

# Confidence intervals for HR, IT, marketing, producct_mng, sales, support, and technical all cross 1, 
# which indicates that the direction of these relationships may be unstable in the population as a whole. 
# Because of this, and because they have p values > .05, they should be considered for removal from the model.

vif(turnoverModel.1)
1/vif(turnoverModel.1)

# Looking at the tolerance values, we can see that for all variables the tolerance values are close 
# to 1 and are much larger than the cut-off point of 0.1 below which suggests there may be a serious 
# collinearity problem. 

# Checking collinearity by generating a correlation matrix using num_df
num_df$number_project <- as.numeric(num_df$number_project)
num_df$average_monthly_hours <- as.numeric(num_df$average_monthly_hours)
num_df$tenure <- as.numeric(num_df$tenure)
num_df$work_accident <- as.numeric(num_df$work_accident)
num_df$left_employer <- as.numeric(num_df$left_employer)
num_df$promotion_last_5years <- as.numeric(num_df$promotion_last_5years)
correlation_matrix <- cor(num_df[, unlist(lapply(num_df, is.numeric))])
write.csv(correlation_matrix, "corr_matrix.csv")

# When we look at the correlation table, we see that most correlations are below 0.3. However, 
# number_project is fairly highly correlated with average_monthly_hours at 0.42, and both were 
# fairly highly correlated with last_evaluation (see table below).
#
#                       last eval   num project   avg monthly hrs
# last eval             1.0
# num project           0.35        1.0
# avg monthly hrs       0.34        0.42          1.0
# 
# It may be best to choose either average_monthly_hours or number_project to include in the model 
# rather than including both.


##### Model 2: A model with everything but number_project----
turnoverModel.2 <- glm(left_employer ~ satisfaction_level + salary + tenure + last_evaluation + 
                          work_accident + average_monthly_hours + promotion_last_5years + department, 
                          data=df, family=binomial())
summary(turnoverModel.2)

# Model 2 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.2$null.deviance - turnoverModel.2$deviance
# Degrees of freedom
chidf <- turnoverModel.2$df.null - turnoverModel.2$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.2)
# Cox and Snell's R squared can be interpreted to mean that turnoverModel.2 can account for 20% 
# of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.2$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.2))

# Confidence intervals for HR, IT, marketing, producct_mng, sales, support, and technical all 
# cross 1, which indicates that the direction of these relationships may be unstable in the 
# population as a whole. Because of this, and because they have p values > .05, they should be 
#considered for removal from the model. In this model, last_evaluation also crosses 1, so it may 
# also be unstable in the population as a whole.

vif(turnoverModel.2)
1/vif(turnoverModel.2)

# Looking at the tolerance values, we can see that for all variables the tolerance values are close 
# to 1 and are much larger than the  cut-off point of 0.1 below which suggests there may be a 
# serious collinearity problem. 

##### Model 3: A model with everything but average_monthly_hours----
turnoverModel.3 <- glm(left_employer ~ satisfaction_level + salary + tenure + last_evaluation + 
                        work_accident + promotion_last_5years + department, data=df, family=binomial())
summary(turnoverModel.3)
# Slightly better than turnoverModel.2 (lower residual deviance)


# Model 3 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.3$null.deviance - turnoverModel.3$deviance
# Degrees of freedom
chidf <- turnoverModel.3$df.null - turnoverModel.3$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.3)
# Cox and Snell's R squared can be interpreted to mean that turnoverModel.2 can account for 20% 
# of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.2$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.2))

# Confidence intervals for HR, IT, marketing, producct_mng, sales, support, and technical all cross 1, 
# which indicates that the direction of these relationships may be unstable in the population as a 
# whole. Because of this, and because they have p values > .05, they should be considered for removal 
# from the model. In this model, last_evaluation also crosses 1, so it may also be unstable in the 
# population as a whole.

vif(turnoverModel.3)
1/vif(turnoverModel.3)

# Looking at the tolerance values, we can see that for all variables the tolerance values are 
# close to 1 and are much larger than the cut-off point of 0.1 below which suggests there may 
# be a serious collinearity problem. 


##### Model 4: A model with binary factors for managment and RandD----
# Recoding department into management and RandD
unique(df$department)

df$management<-dplyr::recode(df$department,'management'=1,'sales'=0, 'accounting'=0,'hr'=0, 'technical'=0,
                             'support'=0, 'IT'=0, 'product_mng'=0, 'marketing'=0, 'RandD'=0)
df$RandD<-dplyr::recode(df$department,'RandD'=1,'sales'=0,'accounting'=0,'hr'=0, 'technical'=0, 'support'=0, 
                              'IT'=0, 'management'=0,'product_mng'=0,'marketing'=0)

# Create the model
turnoverModel.4 <- glm(left_employer ~ satisfaction_level + salary + tenure + last_evaluation + 
                        work_accident + average_monthly_hours + number_project + promotion_last_5years + 
                        management + RandD, data=df, family=binomial())
summary(turnoverModel.4)

# Now that I've created binary factors for management and RandD, all predictors are significant at the 
# alpha = 0.0001 level. However, residuals are slightly higher than in turnoverModel.1.

# Model 4 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.4$null.deviance - turnoverModel.4$deviance
# Degrees of freedom
chidf <- turnoverModel.4$df.null - turnoverModel.4$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.4)

# Cox and Snell's R squared can be interpreted to mean that turnoverModel.4 can account for 21% 
# of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.4$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.4))

# Now that we've created binary variables for management and RandD, none of the confidence intervals 
# cross 1, meaning that the direction of the relationship is clear and that the relationship can 
# probably be generalized to the overall population.

vif(turnoverModel.4)
1/vif(turnoverModel.4)

# Looking at the tolerance values, we can see that for all variables the tolerance values are 
# close to 1 and are much larger than the  cut-off point of 0.1 below which suggests there may 
# be a serious collinearity problem. 


##### Model 5: Model 4 without number_project----
turnoverModel.5 <- glm(left_employer ~ satisfaction_level + salary + tenure + last_evaluation + 
                        work_accident + average_monthly_hours + promotion_last_5years + management + 
                        RandD, data=df, family=binomial())
summary(turnoverModel.5)

# Now residuals are higher than for Model 4 (worse fit), and last_evaluation is no longer significant.

# Model 5 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.5$null.deviance - turnoverModel.5$deviance
# Degrees of freedom
chidf <- turnoverModel.5$df.null - turnoverModel.5$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.5)

# Cox and Snell's R squared can be interpreted to mean that turnoverModel.4 can account for 
# 20% of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.5$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.5))

# In Model 5, the confidence interval for last_evaluation crosses 1, meaning that the 
# direction of the relationship is unclear and not generalizable to the population as a whole.

vif(turnoverModel.5)
1/vif(turnoverModel.5)
# Looking at the tolerance values, we can see that for all variables the tolerance values are 
# close to 1 and are much larger than the cut-off point of 0.1 below which suggests there may 
# be a serious collinearity problem. 

##### Model 6: Model 4 without average_monthly_hours----
turnoverModel.6 <- glm(left_employer ~ satisfaction_level + salary + tenure + last_evaluation + 
                        work_accident + number_project + promotion_last_5years + management + RandD,  
                        data=df, family=binomial())
summary(turnoverModel.6)

# Residuals are somewhat higher than for Model 4 (worse fit), but lower (better fit) than for 
# Model 5. All factors are significant at the alpha = 0.0001 level.

# Model 6 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.6$null.deviance - turnoverModel.6$deviance
# Degrees of freedom
chidf <- turnoverModel.6$df.null - turnoverModel.6$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.6)

# Cox and Snell's R squared can be interpreted to mean that turnoverModel.4 can account for 21% 
# of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.6$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.6))

# In Model 6, none of the confidence intervals cross 1, meaning that the direction of the 
# relationship is clear and likely generalizable to the population as a whole.

vif(turnoverModel.6)
1/vif(turnoverModel.6)
# Looking at the tolerance values, we can see that for all variables  the tolerance values 
# are close to 1 and are much larger than the cut-off point of 0.1 below which suggests 
# there may be a serious collinearity problem. 

##### Model 7: Model 4 without last_evaluation-----
# Create the model
turnoverModel.7 <- glm(left_employer ~ satisfaction_level + salary +
                         tenure + work_accident + 
                         average_monthly_hours + number_project +
                         promotion_last_5years + management + RandD, 
                       data=df, family=binomial())
summary(turnoverModel.7)

# Residuals are slightly higher (worse fit) than in turnoverModel.4. All factors are significant 
# at alpha = .0001 level.

# Model 7 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.7$null.deviance - turnoverModel.7$deviance
# Degrees of freedom
chidf <- turnoverModel.7$df.null - turnoverModel.7$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.7)

# Cox and Snell's R squared can be interpreted to mean that turnoverModel.4 can account for 
# 21% of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.7$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.7))

# None of the confidence intervals cross 1, meaning that the direction of the relationship is 
# clear and that the relationship can probably be generalized to the overall population.

vif(turnoverModel.7)
1/vif(turnoverModel.7)

# Looking at the tolerance values, we can see that for all variables the tolerance values are 
# close to 1 and are much larger than the cut-off point of 0.1 below which suggests there may 
# still be a serious collinearity problem. 


##### Model 8: Model 7 without number_project-----
# Create the model
turnoverModel.8 <- glm(left_employer ~ satisfaction_level + salary + tenure + work_accident + average_monthly_hours +
                         promotion_last_5years + management + RandD, data=df, family=binomial())
summary(turnoverModel.8)

# Residuals are somewhat higher (worse fit) than in turnoverModel.7. All factors are significant 
# at alpha = .0001 level, and the intercept is significant at the alpha = .001 level.

# Model 8 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.8$null.deviance - turnoverModel.8$deviance
# Degrees of freedom
chidf <- turnoverModel.8$df.null - turnoverModel.8$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.8)

# Cox and Snell's R squared can be interpreted to mean that turnoverModel.4  can account for 20% of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.8$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.8))

# None of the confidence intervals cross 1, meaning that the direction of the relationship is clear and that the relationship can probably
# be generalized to the overall population.

vif(turnoverModel.8)
1/vif(turnoverModel.8)

# Looking at the tolerance values, we can see that for all variables the tolerance values are 
# close to 1 and are much larger than the  cut-off point of 0.1 below which suggests there 
# may still be a serious collinearity problem. 

##### Model 9: Model 7 without average_monthly_hours----
# Create the model
turnoverModel.9 <- glm(left_employer ~ satisfaction_level + salary +
                         tenure + work_accident + number_project +
                         promotion_last_5years + management + RandD, 
                       data=df, family=binomial())
summary(turnoverModel.9)

# Residuals are slightly higher (worse fit) than in turnoverModel.7 but better than in turnoverModel.8. All factors are significant at 
# the alpha = .0001 level.

# Model 9 improvement over Baseline
# Difference between the models
modelChi <- turnoverModel.9$null.deviance - turnoverModel.9$deviance
# Degrees of freedom
chidf <- turnoverModel.9$df.null - turnoverModel.9$df.residual
# p value
chisq.prob <- 1 - pchisq(modelChi, chidf)
# Display calculated values
modelChi; chidf; chisq.prob

# Calculate pseudo R squared values
logisticPseudoR2s(turnoverModel.9)

# Cox and Snell's R squared can be interpreted to mean that turnoverModel.4 can account for 
# 21% of the variance in employee turnover

# Odds ratio for predictors in the model
exp(turnoverModel.9$coefficients)

# Confidence intervals for the odds ratio
exp(confint(turnoverModel.9))

# None of the confidence intervals cross 1, meaning that the direction of the relationship 
# is clear and that the relationship can probably be generalized to the overall population.

vif(turnoverModel.9)
1/vif(turnoverModel.9)

# Looking at the tolerance values, we can see that for all variables the tolerance values are 
# close to 1 and are much larger than the cut-off point of 0.1 below which suggests there may 
# be a serious collinearity problem. 
# However, now that last_evaluation and average_monthly_hours have been removed, all of the 
# correlations between factors are below 0.2, and we can be confident in concluding that there 
# is no problem with multicollinearity in these data.
# Model 9 is our best overall model.
