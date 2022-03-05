import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn import metrics #Import scikit-learn metrics module for accuracy calculation
from sklearn import tree
from sklearn.tree import export_graphviz,DecisionTreeClassifier 
from sklearn.tree import _tree
import time

def tree_to_code(tree, feature_names,used_feature):
    tree_ = tree.tree_
    def recurse(node, depth):
        indent = "    " * depth
        #print(indent, node)
        if tree_.feature[node] != _tree.TREE_UNDEFINED:
            name = "feature["+str(tree_.feature[node])+"]" #translate to a compact feature code
            threshold = int(tree_.threshold[node])
            print("{}if {} <= {}:".format(indent, name, threshold))
            recurse(tree_.children_left[node], depth + 1)
            print("{}else:  # if {} > {}".format(indent, name, threshold))
            recurse(tree_.children_right[node], depth + 1)
        else:
            print(indent,"return ",np.argmax(tree_.value[node]))
    recurse(0, 1)

def node_translator(node, used_node, value):
    if node in used_node:
        return used_node.index(node)
    else:
        return value        

def write_file(name,mylist):
    f = open(name, "w")
    for line in mylist:
        # write line to output file
        f.write(line)
        f.write("\n")
    f.close()

def tree_to_mem(tree,used_feature, used_node):
    tree_ = tree.tree_
    Mem_fea=[]
    Mem_thd=[]
    Mem_child=[]
    print("\n"+"final architecture")
    for i in range(256):
        Mem_fea.append('00')
        Mem_thd.append('00')
        Mem_child.append('00')
        Mem_child.append('00') ## each node has two child
    def recurse(node, depth):
        indent = "    " * depth
        cur_node=node_translator(node, used_node,value="leaf")
        if tree_.feature[node] != _tree.TREE_UNDEFINED:
            fea = used_feature.index(tree_.feature[node]) #translate to a compact feature code
            Mem_fea[cur_node]="0x{:02x}".format(fea)[2:]
            threshold = int(tree_.threshold[node])
            Mem_thd[cur_node]="0x{:02x}".format(threshold)[2:]
            print(indent,"Node: ", cur_node,"Feature: ", fea,"Threshold: " , threshold)
            
            l_node=tree_.children_left[node]
            l_value=np.argmax(tree_.value[l_node])
            l_node=node_translator(l_node, used_node, l_value)
            Mem_child[cur_node*2]="0x{:02x}".format(l_node)[2:]
            print(indent+"    ","Left: ", l_node)
            recurse(tree_.children_left[node], depth + 1)
            
            r_node=tree_.children_right[node]
            r_value=np.argmax(tree_.value[r_node])
            r_node=node_translator(r_node, used_node, r_value)
            Mem_child[cur_node*2+1]="0x{:02x}".format(r_node)[2:]
            print(indent+"    ","Right: ", r_node)
            recurse(tree_.children_right[node], depth + 1)
                   
        else:
            print(indent,cur_node,np.argmax(tree_.value[node]))
    recurse(0, 1)
    #write out model parameters
    write_file("fea.hex", Mem_fea)
    write_file("thd.hex", Mem_thd)
    write_file("child.hex", Mem_child)
     
# pre-process
loans = pd.read_csv('loan_data.csv')
final_data = pd.get_dummies(loans, columns = ['purpose'], drop_first = True)
final_data.head(1)
X = final_data.drop('not.fully.paid', axis= 1)
X=(X-X.min())*255.0//(X.max()-X.min())
X=X.astype(int)
y= final_data['not.fully.paid']

#spliting
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=101)


#training and 
weights = {0:np.sum(y_train[:])/(len(y_train[:])*0.5), 1:1.0}
dtc = DecisionTreeClassifier(max_depth=6,class_weight=weights,max_leaf_nodes=16)
dtc.fit(X_train, y_train)
time_start=time.time()
predictions = dtc.predict(X_test)
print("Total inference time using cpu: "+str(time.time()-time_start))
#pruning, code modified from 
#https://stackoverflow.com/questions/51397109/prune-unnecessary-leaves-in-sklearn-decisiontreeclassifier
from sklearn.tree._tree import TREE_LEAF, TREE_UNDEFINED

def is_leaf(inner_tree, index):
    # Check whether node is leaf node
    return (inner_tree.children_left[index] == TREE_LEAF and 
            inner_tree.children_right[index] == TREE_LEAF)

def prune_index(inner_tree, decisions, index=0):
    # Start pruning from the bottom - if we start from the top, we might miss
    # nodes that become leaves during pruning.
    # Do not use this directly - use prune_duplicate_leaves instead.
    used_feature_l=[]
    used_feature_r=[]
    used_node_l=[]
    used_node_r=[]
    if not is_leaf(inner_tree, inner_tree.children_left[index]):
        used_feature_l, used_node_l = prune_index(inner_tree, decisions, inner_tree.children_left[index])
    else:
        used_node_l=[-np.argmax(inner_tree.value[inner_tree.children_left[index]])-1]
    if not is_leaf(inner_tree, inner_tree.children_right[index]):
        used_feature_r, used_node_r = prune_index(inner_tree, decisions, inner_tree.children_right[index])
    else:
        used_node_r=[-np.argmax(inner_tree.value[inner_tree.children_right[index]])-1]
    used_feature_child = used_feature_l+used_feature_r
    used_node_child = used_node_l+used_node_r
    # Prune children if both children are leaves now and make the same decision:     
    if (is_leaf(inner_tree, inner_tree.children_left[index]) and
        is_leaf(inner_tree, inner_tree.children_right[index]) and
        (decisions[index] == decisions[inner_tree.children_left[index]]) and 
        (decisions[index] == decisions[inner_tree.children_right[index]])):
        # turn node into a leaf by "unlinking" its children
        inner_tree.children_left[index] = TREE_LEAF
        inner_tree.children_right[index] = TREE_LEAF
        inner_tree.feature[index] = TREE_UNDEFINED
        ##print("Pruned {}".format(index))
        return [], [-np.argmax(inner_tree.value[index])-1]
    return used_feature_child+[inner_tree.feature[index]], used_node_child+[index]
def prune_duplicate_leaves(mdl):
    # Remove leaves if both  
    decisions = mdl.tree_.value.argmax(axis=2).flatten().tolist() # Decision for each node
    used_feature,used_node=prune_index(mdl.tree_, decisions)
    used_feature.sort()
    used_node.sort()
    used_feature2 = []
    used_node2 = []
    for fea in used_feature:
        if fea not in used_feature2:
            used_feature2.append(fea)
    for node in used_node:
        if node not in used_node2:
            used_node2.append(node)        
    return used_feature2,used_node2    

used_feature, used_node = prune_duplicate_leaves(dtc)
print("feature compress")
for i in range(len(used_feature)):
    print("original index:",used_feature[i], "new index", i,"feature name:",X_test.keys()[used_feature[i]])
#print("node compress", used_node)

#write out data to be fed
data_out=[]
ans_out=[]
temp=X_test.to_numpy()
temp2=predictions
for i in range(len(temp)):
    ans_out.append("0x{:01x}".format(temp2[i])[2:])
    for j in range(len(used_feature)): 
        data_out.append("0x{:02x}".format(temp[i,used_feature[j]])[2:])
write_file("data.hex", data_out)
write_file("ans.hex", ans_out)

'''
# verification for tree conversion
# code modified from: https://stackoverflow.com/questions/56334210/how-to-extract-sklearn-decision-tree-rules-to-pandas-boolean-conditions 
tree_to_code(dtc, X_train.columns,used_feature)
def tree_pred(feature): #paste the result here
    if feature[0] <= 127:
        if feature[1] <= 54:
            if feature[3] <= 75:
                 return  1
            else:  # if feature[3] > 75
                 return  0
        else:  # if feature[1] > 54
             return  1
    else:  # if feature[0] > 127
        if feature[1] <= 55:
            if feature[2] <= 150:
                if feature[5] <= 157:
                    if feature[8] <= 161:
                         return  0
                    else:  # if feature[8] > 161
                         return  1
                else:  # if feature[5] > 157
                     return  0
            else:  # if feature[2] > 150
                 return  1
        else:  # if feature[1] > 55
            if feature[17] <= 127:
                 return  0
            else:  # if feature[17] > 127
                if feature[6] <= 73:
                     return  1
                else:  # if feature[6] > 73
                     return  0
counter=0
for i in range(len(y_test)):
    if (tree_pred(X_test.to_numpy()[i])!=predictions[i]):
        counter+=1
        print("result different!!",counter)
'''
#write out model parameters
tree_to_mem(dtc, used_feature, used_node)

#visualization
plt.figure(figsize=(36,12))
tree.plot_tree(dtc, fontsize=6)
plt.savefig('tree_high_dpi', dpi=100)

# performance
from sklearn.metrics import classification_report, confusion_matrix
#print(classification_report(y_test, predictions))
print("Accuracy:",metrics.accuracy_score(y_test, predictions))
print("F1:",metrics.f1_score(y_test, predictions))
print("Confusion Matrix:\n",confusion_matrix(y_test, predictions))
 