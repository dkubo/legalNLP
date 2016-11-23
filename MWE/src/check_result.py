#coding: utf-8

# マッチスパンが入れ子or 包含になっているものを確認
# マッチMWEの種類数カウント

RESULT="../result/matced_mwe.csv"

def main():
	with open(RESULT, "r") as f:
		for line in f:
			print(line)

if __name__ == '__main__':
	main()